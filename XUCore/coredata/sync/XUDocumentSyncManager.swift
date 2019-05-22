//
//  XUDocumentSyncManager.swift
//  XUCore
//
//  Created by Charlie Monroe on 5/23/16.
//  Copyright © 2016 Charlie Monroe Software. All rights reserved.
//

import Foundation
import CloudKit
import CoreData

#if os(iOS)
import UIKit // For UIBackgroundTaskIdentifier and UIDevice
#endif

@available(iOSApplicationExtension, unavailable)
public protocol XUDocumentSyncManagerDelegate: AnyObject {

	/// This method is called when the sync manager fails to save information
	/// about the sync changes - this is likely pointing to a bug in XUSyncEngine,
	/// but it may be a good idea to inform the user about this anyway.
	func documentSyncManager(_ manager: XUDocumentSyncManager, didFailToSaveSynchronizationContextWithError error: NSError)

	/// Optional method that informs the delegate that the manager has encountered
	/// an error during synchronization and the error isn't fatal.
	func documentSyncManager(_ manager: XUDocumentSyncManager, didEncounterNonFatalErrorDuringSynchronization error: NSError)

	/// Optional method that informs the delegate that the manager has finished
	/// synchronization.
	func documentSyncManagerDidSuccessfullyFinishSynchronization(_ manager: XUDocumentSyncManager)

}

@available(iOSApplicationExtension, unavailable)
public extension XUDocumentSyncManagerDelegate {
	func documentSyncManager(_ manager: XUDocumentSyncManager, didEncounterNonFatalErrorDuringSynchronization error: NSError) {}
	func documentSyncManagerDidSuccessfullyFinishSynchronization(_ manager: XUDocumentSyncManager) {}
}


private let XUDocumentSyncManagerErrorDomain = "XUDocumentSyncManagerErrorDomain"

private let XUDocumentLastUploadDateKey = "XUDocumentLastUploadDate"
private let XUDocumentLastSyncChangeSetTimestampKey = "XUDocumentLastSyncChangeSetTimestamp"
private let XUDocumentNameKey = "XUDocumentName"


/// The document sync manager will use CloudKit to push changes. Always. To configure
/// the CloudKit, create a zone with the name "XUCore.Synchronization" and two types:
///
/// - XUSynchronizedDevice with fields "name", "uuid" (both strings)
/// - XUChangeSet with fields "documentID" (string), "timestamp" (Date/Time),
///			"deviceID" (string), "payload" (Bytes) and "asset" (Asset).
///
/// Additionally, you need to make an queryable index for XUSynchronizedDevice.uuid,
/// XUChangeSet.documentID, XUChangeSet.timestamp, XUChangeSet.deviceID, XUChangeSet.recordName.
/// And XUChangeSet.timestamp must be also sortable.
///
/// The sync manager automatically creates a subscription to changes, so you may
/// create a remote notification callback in your app delegate and just pass the
/// CKNotification to XUDocumentSyncManager.processRemoteNotification(_:). The manager
/// will find the correct document to start the sync with.
///
/// Each time the document sync manager applies some sync changes, it posts a notification
/// XUDocumentSyncManager.didApplySynchronizationChangesNotification. You should catch that and
/// refresh the UI.
@available(iOSApplicationExtension, unavailable)
open class XUDocumentSyncManager {
	
	
	/// Weak references to current sync managers. This way we can handle notifications
	/// correctly.
	private static var _documents: XUWeakArray<XUDocumentSyncManager> = XUWeakArray<XUDocumentSyncManager>()
	
	
	/// Posted when synchronization changes are applied. Note - if it synchronizes
	/// with no changes at all, no notification is posted.
	public static let didApplySynchronizationChangesNotification: Notification.Name = Notification.Name(rawValue: "XUDidApplySynchronizationChangesNotification")
	
	/// Synchronously downloads document with document ID to URL and returns error,
	/// if the download wasn't successful.
	///
	/// The returned URL points to the actual document.
	open class func downloadDocument(withID documentID: String, forApplicationSyncManager appSyncManager: XUApplicationSyncManager, toURL fileURL: URL) throws -> URL {
		
		guard let config = self.urlOfNewestEntireDocument(withUUID: documentID, forApplicationSyncManager: appSyncManager) else {
			
			XULog("Document sync manager was unable to find whole-store upload for document with ID \(documentID)")
			
			throw NSError(domain: XUDocumentSyncManagerErrorDomain, code: 0, userInfo: [
				NSLocalizedFailureReasonErrorKey : XULocalizedString("Cannot find such document. Check back later, it might not have synced through.", inBundle: .core)
			])
		}
		
		var documentURL: URL?
		var error: NSError?
		var innerError: NSError?
		
		let coordinator = NSFileCoordinator(filePresenter: nil)
		coordinator.coordinate(readingItemAt: config.accountURL, options: .withoutChanges, error: &error, byAccessor: { (newURL) in
			let infoFileURL = config.accountURL.deletingLastPathComponent().appendingPathComponent("Info.plist")
			
			guard let accountDict = NSDictionary(contentsOf: infoFileURL) as? XUJSONDictionary else {
				innerError = NSError(domain: XUDocumentSyncManagerErrorDomain, code: 0, userInfo: [
					NSLocalizedFailureReasonErrorKey : XULocalizedString("Cannot open document metadata file.", inBundle: .core)
				])
				return
			}
			
			guard let documentName = accountDict[XUDocumentNameKey] as? String else {
				innerError = NSError(domain: XUDocumentSyncManagerErrorDomain, code: 0, userInfo: [
					NSLocalizedFailureReasonErrorKey : XULocalizedString("Metadata file doesn't contain required information.", inBundle: .core)
				])
				return
			}
		
			FileManager.default.createDirectory(at: fileURL)
		
			let remoteDocumentURL = config.accountURL.appendingPathComponent(documentName)
			let localDocumentURL = fileURL.appendingPathComponent(documentName)
		
			do {
				try FileManager.default.copyItem(at: remoteDocumentURL, to: localDocumentURL)
				
				documentURL = localDocumentURL
				
				XUPreferences.shared.perform(andSynchronize: { (prefs) in
					prefs.setTimestampOfImport(config.lastSync, for: documentID)
				})
			} catch let localError as NSError {
				innerError = localError
			}
		})
		
		error = error ?? innerError
		
		if let error = error {
			throw error
		}
		
		guard let docURL = documentURL else {
			throw NSError(domain: XUDocumentSyncManagerErrorDomain, code: 0, userInfo: [
				NSLocalizedFailureReasonErrorKey : XULocalizedString("The document could not be downloaded at this moment.", inBundle: .core)
			])
		}
		
		return docURL
	}
	
	/// You should pass here the remote notification from the app delegate to force
	/// an automatic sync for an account that this notification is for.
	public class func processRemoteNotification(_ notification: CKNotification) {
		guard let subscriptionID = notification.subscriptionID else {
			XULog("Can't process notification as it has no subscription ID: \(notification)")
			return
		}
		
		guard let subscription = XUCloudKitDeviceRegistry.SubscriptionID(rawValue: subscriptionID) else {
			XULog("Can't process notification as its subscription ID is not compatible with this sync: \(notification)")
			return
		}
		
		guard let document = _documents.first(where: { $0.documentID == subscription.documentID }) else {
			return // Probably not opened now.
		}
		
		if !document._isSyncing {
			document.startSynchronizing(withCompletionHandler: { _, _ in })
		}
	}
	
	/// This method goes through all the whole store uploads and looks for the
	/// newest whole store upload. Note that this method uses NSFileCoordinator 
	/// to read the metadata which is likely to block the thread for some while 
	/// if the file isn't downloaded yet. Hence do not call this from main thread.
	///
	/// The most common usage for this is from XUApplicationSyncManager when 
	/// downloading a document with certain UUID.
	///
	/// computerID contains the ID of the computer from which we're downloading
	/// the document. Nil if not successful.
	open class func urlOfNewestEntireDocument(withUUID documentID: String, forApplicationSyncManager appSyncManager: XUApplicationSyncManager) -> (accountURL: URL, computerID: String, lastSync: TimeInterval)? {
		guard let folderURL = XUSyncManagerPathUtilities.documentFolderURL(for: appSyncManager, documentUUID: documentID) else {
			return nil
		}
		
		let coordinator = NSFileCoordinator(filePresenter: nil)
		var newestURL: URL?
		var newestDate: TimeInterval = 0.0
		var newestComputerID: String?
		var lastSync: TimeInterval = 0.0
		
		coordinator.coordinate(readingItemAt: folderURL, options: .withoutChanges, error:nil, byAccessor: { (newURL) in
			let contents = FileManager.default.contentsOfDirectory(at: newURL)
			for computerURL in contents {
				let computerID = computerURL.lastPathComponent
				guard computerID != ".DS_Store", !computerID.isEmpty else {
					continue
				}
			
				guard let infoFileURL = XUSyncManagerPathUtilities.entireDocumentInfoFileURL(for: appSyncManager, deviceID: computerID, documentID: documentID) else {
					continue
				}
				
				guard let dict = NSDictionary(contentsOf: infoFileURL) as? XUJSONDictionary else {
					_ = try? appSyncManager.startDownloading(itemAt: infoFileURL)
					continue
				}
			
				let timeInterval = dict.double(forKey: XUDocumentLastUploadDateKey)
				if timeInterval == 0.0 {
					continue
				}
				
				if newestDate == 0.0 || timeInterval > newestDate {
					newestDate = timeInterval
					guard let wholeStoreURL = XUSyncManagerPathUtilities.entireDocumentFolderURL(for: appSyncManager, deviceID: computerID, documentID: documentID) else {
						continue
					}
					
					newestURL = wholeStoreURL.appendingPathComponent("Document")
					newestComputerID = computerID
					lastSync = timeInterval
				}
			}
		})
		
		if newestURL == nil || newestComputerID == nil {
			return nil
		}
		
		return (newestURL!, newestComputerID!, lastSync)
	}

	
	/// The app sync manager this document is tied to. This connection is required
	/// since we need to know where to put the sync data.
	public final let applicationSyncManager: XUApplicationSyncManager
	
	/// CloudKit container containing all the sync changes.
	public final let cloudKitContainer: CKContainer
	
	/// Record zone for the synchronization stuff.
	public final let cloudKitContainerRecordZone: CKRecordZone = CKRecordZone(zoneName: "XUCore.Synchronization")
	
	/// Delegate.
	public final weak var delegate: XUDocumentSyncManagerDelegate?
	
	/// Main object context that was passed in the initializer.
	public final let managedObjectContext: NSManagedObjectContext
	
	/// ID of the document - should be unique system-wide, e.g. UUID.
	public final let documentID: String
	
	
	/// Device registry.
	private let _deviceRegistry: XUCloudKitDeviceRegistry
	
	/// Lock used for ensuring that only one synchronization is done at once.
	private let _synchronizationLock: NSLock = NSLock(name: "com.charliemonroe.XUCore.XUDocumentSyncManager")
	
	
	#if os(iOS)
		/// Background task while syncing.
	private var _syncBackgroundTaskIdentifier: UIBackgroundTaskIdentifier = UIBackgroundTaskIdentifier.invalid
	#endif
	
	
	private var _isSyncing: Bool = false
	private var _isUploadingEntireDocument: Bool = false
	private var _synchronization: XUCloudKitSynchronization?
	
	
	/// This method is an observer for NSManagedObjectContextWillSaveNotification.
	@objc private func _createSyncChanges(_ aNotif: Notification) {
		if !Thread.isMainThread {
			DispatchQueue.main.syncOrNow { self._createSyncChanges(aNotif) }
			return
		}
	
		XULog("\(self) - managed object context will save, creating sync changes.")
	
		var changes: [XUSyncChange] = []
		changes += self._createSyncChanges(forObjects: self.managedObjectContext.insertedObjects)
		changes += self._createSyncChanges(forObjects: self.managedObjectContext.updatedObjects)
		changes += self._createSyncChanges(forObjects: self.managedObjectContext.deletedObjects)
	
		guard !changes.isEmpty else {
			// Do not create anything.
			self.delegate?.documentSyncManagerDidSuccessfullyFinishSynchronization(self)
			return
		}
	
		// Create a change set.
		let set = XUSyncChangeSet(changes: changes)
		XULog("\(self) - created change set \(set.timestamp) with \(changes.count) changes")
	
		let encodedSet = NSKeyedArchiver.archivedData(withRootObject: set)
		XUPreferences.shared.perform { (prefs) in
			var data = prefs.pendingSynchronizationChanges(for: self.documentID).map({ $0.data })
			data.append(encodedSet)
			prefs.setPendingSynchronizationChanges(data, for: self.documentID)
			prefs.setLastSynchronizationChangeTimestamp(set.timestamp, for: self.documentID)
		}

		self.delegate?.documentSyncManagerDidSuccessfullyFinishSynchronization(self)
	}
	
	private func _createSyncChanges(forObjects objects: Set<NSManagedObject>) -> [XUSyncChange] {
		var changes: [XUSyncChange] = []
		for obj in objects {
			guard let managedObj = obj as? XUManagedObject else {
				XULog("Found an object that is not XUManagedObject subclass: \(obj)")
				continue
			}
			
			changes += managedObj.createSyncChanges()
		}
		
		return changes
	}
	
	/// This method is an observer for NSManagedObjectContextWillSaveNotification.
	/// We start a sync after each save.
	@objc private func _startSync(_ aNotif: Notification) {
		self.startSynchronizing { (success, error) in
			if success {
				XULog("\(self) - successfully completed synchronization.")
			} else {
				XULog("\(self) - failed synchronization with error \(error!).")
			}
		}
	}

	deinit {
		XULog("Deiniting sync manager for document \(self.documentID)")
	}
	
	/// Inits the document sync manager with fileURL, appSyncManager and UUID.
	/// Returns nil, if iCloud is off.
	public init(managedObjectContext: NSManagedObjectContext, applicationSyncManager appSyncManager: XUApplicationSyncManager, documentID: String) throws {
		self.applicationSyncManager = appSyncManager
		self.documentID = documentID

		guard let cloudKitIdentifier = XUAppSetup.iCloudSynchronizationContainerIdentifier else {
			XUFatalError("This application does not have a valid iCloud synchronization container identifier. See XUApplicationSetup for more information.")
		}
		
		self.cloudKitContainer = CKContainer(identifier: cloudKitIdentifier)
		_deviceRegistry = XUCloudKitDeviceRegistry(database: self.cloudKitContainer.privateCloudDatabase, recordZone: self.cloudKitContainerRecordZone, documentID: documentID)
		
		self.managedObjectContext = managedObjectContext
		
		XUDocumentSyncManager._documents.append(self)
		XUDocumentSyncManager._documents.performCleanup()
		
		NotificationCenter.default.addObserver(self, selector: #selector(_createSyncChanges(_:)), name: NSNotification.Name.NSManagedObjectContextWillSave, object: managedObjectContext)
		NotificationCenter.default.addObserver(self, selector: #selector(_startSync(_:)), name: NSNotification.Name.NSManagedObjectContextDidSave, object: managedObjectContext)
	}
	
	/// Starts synchronization with other devices.
	open func startSynchronizing(withCompletionHandler completionHandler: @escaping (Bool, Error?) -> Void) {
		_synchronizationLock.lock()
		guard !_isSyncing else {
			// Already syncing
			_synchronizationLock.unlock()
			completionHandler(false, NSError(domain: XUDocumentSyncManagerErrorDomain, code: 0, userInfo: [
				NSLocalizedFailureReasonErrorKey: XULocalizedString("Synchronization is already in progress.", inBundle: .core)
			]))
			return
		}
		
		guard !self.applicationSyncManager.isDownloadingData else {
			// App manager is downloading data.
			_synchronizationLock.unlock()
			completionHandler(false, NSError(domain: XUDocumentSyncManagerErrorDomain, code: 0, userInfo: [
				NSLocalizedFailureReasonErrorKey: XULocalizedString("Synchronization data is being downloaded.", inBundle: .core)
			]))
			return
		}
	
		_isSyncing = true
		_synchronizationLock.unlock()
	
		#if os(iOS)
			_syncBackgroundTaskIdentifier = UIApplication.shared.beginBackgroundTask(withName: "XUDocumentSyncManager.Sync", expirationHandler: {
				if self._syncBackgroundTaskIdentifier == UIBackgroundTaskIdentifier.invalid {
					return
				}
				
				// The sync hasn't finished yet. Inform the user.
				self._syncBackgroundTaskIdentifier = UIBackgroundTaskIdentifier.invalid

				let notification = UILocalNotification()
				notification.alertTitle = XULocalizedFormattedString("%@ couldn't finish synchronization in the background.", ProcessInfo.processInfo.processName)
				notification.alertBody =  XULocalizedFormattedString("Please switch back to %@ so that the synchronization can finish.", ProcessInfo.processInfo.processName)
				notification.fireDate = Date(timeIntervalSinceNow: 1.0)
		
				UIApplication.shared.scheduleLocalNotification(notification)
			})
		#endif
		
		let synchronization = XUCloudKitSynchronization(documentManager: self) { (error) in
			self._synchronizationLock.lock()
			self._isSyncing = false
			self._synchronizationLock.unlock()
			
			completionHandler(error == nil, error)
			
			#if os(iOS)
				UIApplication.shared.endBackgroundTask(self._syncBackgroundTaskIdentifier)
			self._syncBackgroundTaskIdentifier = UIBackgroundTaskIdentifier.invalid
			#endif
		}
		synchronization.startSynchronization()
		
		_synchronization = synchronization
	}
	
	/// Uploads the entire document to the cloud.
	open func uploadEntireDocument(fromURL fileURL: URL, withCompletionHandler completionHandler: @escaping (Bool, NSError?) -> Void) {
		XUAssert(Thread.isMainThread, "This methos must be called from the main thread!")
		
		// The _isUploadingEntireDocument flag is only changed from main thread
		// so no locks are necessary
		if _isUploadingEntireDocument {
			completionHandler(false, NSError(domain: XUDocumentSyncManagerErrorDomain, code: 0, userInfo: [
				NSLocalizedFailureReasonErrorKey: XULocalizedString("An upload operation is already in progress.", inBundle: .core)
			]))
			return
		}
	
		_isUploadingEntireDocument = true
	
		let lastChangeSetTimestamp = XUPreferences.shared.lastSynchronizationChangeTimestamp(for: self.documentID) ?? 0.0
	
		// Copy the document somewhere else, since the upload may take some time 
		// and changes may be made.
		let tempFolderURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(NSUUID().uuidString)
		
		FileManager.default.createDirectory(at: tempFolderURL)
	
		do {
			try FileManager.default.copyItem(at: fileURL, to: tempFolderURL.appendingPathComponent(fileURL.lastPathComponent))
		} catch let error as NSError {
			completionHandler(false, error)
			_isUploadingEntireDocument = false
			return
		}
		
		guard let entireDocumentFolderURL = XUSyncManagerPathUtilities.entireDocumentFolderURL(for: self.applicationSyncManager, deviceID: XUSyncManagerPathUtilities.currentDeviceIdentifier, documentID: self.documentID) else {
			let error = NSError(domain: XUDocumentSyncManagerErrorDomain, code: 0, userInfo: [
				NSLocalizedFailureReasonErrorKey: XULocalizedFormattedString("Can't find synchronization folder for document %@.", self.documentID)
			])
			completionHandler(false, error)
			_isUploadingEntireDocument = false
			return
		}
	
		DispatchQueue.global(qos: .default).async {
			let coordinator = NSFileCoordinator(filePresenter: nil)
			var err: NSError?
			var innerError: NSError?
			var success: Bool = true
			coordinator.coordinate(writingItemAt: entireDocumentFolderURL, options: .forReplacing, error: &err, byAccessor: { (newURL) in
				let docURL = newURL.appendingPathComponent("Document")
				
				_ = try? self.applicationSyncManager.createDirectory(at: docURL)
	
				let targetURL = docURL.appendingPathComponent(fileURL.lastPathComponent)
	
				// Delete the old whole-store
				do {
					_ = try? FileManager.default.removeItem(at: targetURL) // It may not exist
					FileManager.default.createDirectory(at: tempFolderURL, withIntermediateDirectories: true)
					
					try FileManager.default.copyItem(at: tempFolderURL.appendingPathComponent(fileURL.lastPathComponent), to: targetURL)
					
					self.applicationSyncManager.didUpdateFile(at: targetURL)
				} catch let error as NSError {
					innerError = error
					success = false
					return
				}
	
				let documentConfig = [
					XUDocumentLastUploadDateKey: Date.timeIntervalSinceReferenceDate,
					XUDocumentLastSyncChangeSetTimestampKey: lastChangeSetTimestamp,
					XUDocumentNameKey: fileURL.lastPathComponent
				] as NSDictionary
	
				let configURL = newURL.appendingPathComponent("Info.plist")
				if !documentConfig.write(to: configURL, atomically: true) {
					success = false
					innerError = NSError(domain: XUDocumentSyncManagerErrorDomain, code: 0, userInfo: [
						NSLocalizedFailureReasonErrorKey: XULocalizedString("Could not save upload metadata.", inBundle: .core)
					])
					return
				}
	
				self.applicationSyncManager.didUpdateFile(at: configURL)
				success = true
			})
			
			err = err ?? innerError
	
			DispatchQueue.main.syncOrNow(execute: { 
				completionHandler(success, err)
				self._isUploadingEntireDocument = false
			})
		}
	}
	
}
