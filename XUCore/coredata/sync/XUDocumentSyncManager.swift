//
//  XUDocumentSyncManager.swift
//  XUCore
//
//  Created by Charlie Monroe on 5/23/16.
//  Copyright © 2016 Charlie Monroe Software. All rights reserved.
//

import Foundation
import CoreData

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

public extension XUDocumentSyncManagerDelegate {
	public func documentSyncManager(_ manager: XUDocumentSyncManager, didEncounterNonFatalErrorDuringSynchronization error: NSError) {}
	public func documentSyncManagerDidSuccessfullyFinishSynchronization(_ manager: XUDocumentSyncManager) {}
}


private let XUDocumentSyncManagerErrorDomain = "XUDocumentSyncManagerErrorDomain"

private let XUDocumentLastUploadDateKey = "XUDocumentLastUploadDate"
private let XUDocumentLastSyncChangeSetTimestampKey = "XUDocumentLastSyncChangeSetTimestamp"
private let XUDocumentNameKey = "XUDocumentName"

private let XUDocumentLastProcessedChangeSetKey = "XUDocumentLastProcessedChangeSet"



open class XUDocumentSyncManager {
	
	/// Synchronously downloads document with document ID to URL and returns error,
	/// if the download wasn't successful.
	///
	/// The returned NSURL points to the actual document.
	open class func downloadDocument(withID documentID: String, forApplicationSyncManager appSyncManager: XUApplicationSyncManager, toURL fileURL: URL) throws -> URL {
		
		guard let config = self.urlOfNewestEntireDocument(withUUID: documentID, forApplicationSyncManager: appSyncManager) else {
			
			XULog("Document sync manager was unable to find whole-store upload for document with ID \(documentID)")
			
			throw NSError(domain: XUDocumentSyncManagerErrorDomain, code: 0, userInfo: [
				NSLocalizedFailureReasonErrorKey : XULocalizedString("Cannot find such document. Check back later, it might not have synced through.", inBundle: XUCoreFramework.bundle)
			])
		}
		
		var documentURL: URL?
		var error: NSError?
		
		let coordinator = NSFileCoordinator(filePresenter: nil)
		coordinator.coordinate(readingItemAt: config.accountURL, options: .withoutChanges, error: &error, byAccessor: { (newURL) in
			let infoFileURL = config.accountURL.deletingLastPathComponent().appendingPathComponent("Info.plist")
			
			guard let accountDict = NSDictionary(contentsOf: infoFileURL) as? XUJSONDictionary else {
				error = NSError(domain: XUDocumentSyncManagerErrorDomain, code: 0, userInfo: [
					NSLocalizedFailureReasonErrorKey : XULocalizedString("Cannot open document metadata file.", inBundle: XUCoreFramework.bundle)
				])
				return
			}
			
			guard let documentName = accountDict[XUDocumentNameKey] as? String else {
				error = NSError(domain: XUDocumentSyncManagerErrorDomain, code: 0, userInfo: [
					NSLocalizedFailureReasonErrorKey : XULocalizedString("Metadata file doesn't contain required information.", inBundle: XUCoreFramework.bundle)
				])
				return
			}
		
			FileManager.default.createDirectory(at: fileURL)
		
			let remoteDocumentURL = config.accountURL.appendingPathComponent(documentName)
			let localDocumentURL = fileURL.appendingPathComponent(documentName)
		
			do {
				try FileManager.default.copyItem(at: remoteDocumentURL, to: localDocumentURL)
				
				documentURL = localDocumentURL
				
				// We need to copy the sync timestamp
				guard let syncInfoURL = XUSyncManagerPathUtilities.persistentSyncStorageInfoURLForSyncManager(appSyncManager, computerID: config.computerID, andDocumentUUID: documentID) else {
					error = NSError(domain: XUDocumentSyncManagerErrorDomain, code: 0, userInfo: [
						NSLocalizedFailureReasonErrorKey : XULocalizedString("Cannot open document metadata file.", inBundle: XUCoreFramework.bundle)
						])
					return
				}
				
				try appSyncManager.createDirectory(at: syncInfoURL.deletingLastPathComponent())
				
				let timeStamp = accountDict.double(forKey: XUDocumentLastUploadDateKey)
				let syncInfoDict: NSDictionary = [
					XUDocumentLastProcessedChangeSetKey: timeStamp
				]
				
				syncInfoDict.write(to: syncInfoURL, atomically: true)
				appSyncManager.didUpdateFile(at: syncInfoURL)
			} catch let localError as NSError {
				error = localError
			}
		})
		
		if let error = error {
			throw error
		}
		
		guard let docURL = documentURL else {
			throw NSError(domain: XUDocumentSyncManagerErrorDomain, code: 0, userInfo: [
				NSLocalizedFailureReasonErrorKey : XULocalizedString("The document could not be downloaded at this moment.", inBundle: XUCoreFramework.bundle)
			])
		}
		
		return docURL
	}
	
	/// This method goes through all the whole store uploads and looks for the
	/// newest whole store upload. Note that this method uses NSFileCoordinator 
	/// to read the metadata which is likely to block the thread for some while 
	/// if the file isn't downloaded yet. Hence do not call this from main thread.
	///
	/// The most common usage for this is from XUApplicationSyncManager when 
	/// downloading a document with certain UUID.
	///
	/// computerIDPtr contains the ID of the computer from which we're downloading 
	/// the document. Nil if not successful.
	open class func urlOfNewestEntireDocument(withUUID documentID: String, forApplicationSyncManager appSyncManager: XUApplicationSyncManager) -> (accountURL: URL, computerID: String)? {
		guard let folderURL = XUSyncManagerPathUtilities.documentFolderURLForSyncManager(appSyncManager, andDocumentUUID: documentID) else {
			return nil
		}
		
		let coordinator = NSFileCoordinator(filePresenter: nil)
		var newestURL: URL?
		var newestDate: Date?
		var newestComputerID: String?
		
		coordinator.coordinate(readingItemAt: folderURL, options: .withoutChanges, error:nil, byAccessor: { (newURL) in
			let contents = FileManager.default.contentsOfDirectory(at: newURL)
			for computerURL in contents {
				let computerID = computerURL.lastPathComponent
				guard computerID != ".DS_Store", !computerID.isEmpty else {
					continue
				}
			
				guard let infoFileURL = XUSyncManagerPathUtilities.entireDocumentInfoFileURLForSyncManager(appSyncManager, computerID: computerID, andDocumentUUID: documentID) else {
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
				
				let fileDate = Date(timeIntervalSinceReferenceDate: timeInterval)
				if newestDate == nil || fileDate.compare(newestDate!) == .orderedDescending {
					newestDate = fileDate
					guard let wholeStoreURL = XUSyncManagerPathUtilities.entireDocumentFolderURLForSyncManager(appSyncManager, computerID: computerID, andDocumentUUID: documentID) else {
						continue
					}
					
					newestURL = wholeStoreURL.appendingPathComponent("Document")
					newestComputerID = computerID
				}
			}
		})
		
		if newestURL == nil || newestComputerID == nil {
			return nil
		}
		
		return (newestURL!, newestComputerID!)
	}

	
	/// The app sync manager this document is tied to. This connection is required
	/// since we need to know where to put the sync data.
	public final let applicationSyncManager: XUApplicationSyncManager
	
	/// Delegate.
	public final weak var delegate: XUDocumentSyncManagerDelegate?
	
	/// Main object context that was passed in the initializer.
	public final let managedObjectContext: NSManagedObjectContext
	
	/// MOC used for sync changes.
	public final let syncManagedObjectContext: NSManagedObjectContext
	
	/// UUID of the document.
	public final let uuid: String


	/// URL to the CoreData file that contains sync changes.
	private var _currentComputerSyncURL: URL!
	
	/// URL to the CoreData file that we're actually writing changes (in temp
	/// dir).
	private let _currentComputerTempSyncURL: URL
	
	/// Lock used for ensuring that only one synchronization is done at once.
	private let _synchronizationLock = NSLock(name: "")
	
	/// Model used in -syncManagedObjectContext.
	private let _syncModel: NSManagedObjectModel
	
	/// Persistent store coordinator used in -syncManagedObjectContext.
	private let _syncStoreCoordinator: NSPersistentStoreCoordinator
	
	#if os(iOS)
		/// Background task while syncing.
		private var _syncBackgroundTaskIdentifier: UIBackgroundTaskIdentifier = UIBackgroundTaskInvalid
	#endif
	
	
	private var _isSyncing: Bool = false
	private var _isUploadingEntireDocument: Bool = false
	
	
	/// Applies changes from changeSet and returns error.
	///
	/// objCache is a mutable dictionary with UUID -> obj mapping that is kept 
	/// during the sync, so that we don't have to perform fetches unless necessary.
	private func _apply(changeSet: XUSyncChangeSet, withObjectCache objCache: inout [String : XUManagedObject]) -> [NSError] {
		let changes = changeSet.changes
	
		var errors: [NSError] = []
		
		// We need to apply insertion changes first since other changes may include
		// relationship changes, which include these entities
		let insertionChanges = changes.filter({ $0 is XUInsertionSyncChange }) as! [XUInsertionSyncChange]
		for change in insertionChanges {
			XULog("Applying insertion change [\(change.insertedEntityName)]")
			
			guard let entityDescription = NSEntityDescription.entity(forEntityName: change.insertedEntityName, in: self.managedObjectContext) else {
				errors.append(NSError(domain: XUDocumentSyncManagerErrorDomain, code: 0, userInfo: [
					NSLocalizedFailureReasonErrorKey: XULocalizedFormattedString("Cannot find entity named %@", change.insertedEntityName)
				]))
				continue
			}
	
			guard let cl = NSClassFromString(entityDescription.managedObjectClassName) as? XUManagedObject.Type else {
				errors.append(NSError(domain: XUDocumentSyncManagerErrorDomain, code: 0, userInfo: [
					NSLocalizedFailureReasonErrorKey: XULocalizedFormattedString("Cannot find class named %@", entityDescription.managedObjectClassName)
				]))
				continue
			}
	
			var obj: XUManagedObject!
			
			let fetchRequest = NSFetchRequest<XUManagedObject>(entityName: change.objectEntityName)
			fetchRequest.predicate = NSPredicate(format: "ticdsSyncID == %@", change.objectSyncID)
			
			obj = (try? self.managedObjectContext.fetch(fetchRequest))?.first
			if obj != nil {
				XULog("Object with ID \(obj.syncUUID) already exists!")
				continue
			}
	
			obj = cl.init(entity: entityDescription, insertInto: self.managedObjectContext, asResultOfSyncAction: true)
			
			let attributes = change.attributes
			for (key, value) in attributes {
				obj.isApplyingSyncChange = true
				
				XUExceptionCatcher.perform({ 
					obj.setValue(value, forKey: key)
				}, withCatchHandler: { (exception) in
					XULog("Failed setting \(value) for key \(key) on \(change.insertedEntityName) - \(exception).")
				}, andFinallyBlock: { 
					obj.isApplyingSyncChange = false
				})
			}
	
			XUManagedObject.noticeSyncInsertionOfObject(withID: obj.syncUUID)
			objCache[obj.syncUUID] = obj
		}
	
		// Done with insertion - now get the remaining changes and apply them
		let otherChanges = changes.filter({ !($0 is XUInsertionSyncChange) })
		
		for change in otherChanges {
			XULog("Applying change [\(change.entity.name.descriptionWithDefaultValue())]")
			
			var obj: XUManagedObject! = objCache[change.objectSyncID]
			if obj == nil {
				let fetchRequest = NSFetchRequest<XUManagedObject>(entityName: change.objectEntityName)
				fetchRequest.predicate = NSPredicate(format: "ticdsSyncID == %@", change.objectSyncID)
				obj = (try? self.managedObjectContext.fetch(fetchRequest))?.first
			}
		
			if obj == nil {
				errors.append(NSError(domain: XUDocumentSyncManagerErrorDomain, code: 0, userInfo: [
					NSLocalizedFailureReasonErrorKey: XULocalizedFormattedString("Cannot find entity with ID %@", change.objectSyncID)
				]))
				continue
			}
		
			obj.apply(syncChange: change)
		}
		
		return errors
	}

	/// This method is an observer for NSManagedObjectContextWillSaveNotification.
	@objc private func _createSyncChanges(_ aNotif: Notification) {
		if !Thread.isMainThread {
			XU_PERFORM_BLOCK_ON_MAIN_THREAD { self._createSyncChanges(aNotif) }
			return
		}
	
		XULog("\(self) - managed object context will save, creating sync changes.")
	
		var changes: [XUSyncChange] = []
		changes += self._createSyncChanges(forObjects: self.managedObjectContext.insertedObjects)
		changes += self._createSyncChanges(forObjects: self.managedObjectContext.updatedObjects)
		changes += self._createSyncChanges(forObjects: self.managedObjectContext.deletedObjects)
	
		if changes.count == 0 {
			// Do not create anything.
			XU_PERFORM_BLOCK_ON_MAIN_THREAD {
				self.delegate?.documentSyncManagerDidSuccessfullyFinishSynchronization(self)
			}
			
			// Don't even do sync cleanup, we'll simply do it next time
			return
		}
	
		// Create a change set.
		let set = XUSyncChangeSet(managedObjectContext: self.syncManagedObjectContext, andChanges: changes)
		XULog("\(self) - created change set \(set.timestamp) with \(changes.count) changes")
	
		self._performSyncCleanup()
	
		do {
			try self.syncManagedObjectContext.save()
			
			// The context is saved in a temporary location - copy it over to the 
			// cloud.
			guard let originalData = try? Data(contentsOf: _currentComputerTempSyncURL) else {
				throw NSError(domain: XUDocumentSyncManagerErrorDomain, code: 0, userInfo: [
					NSLocalizedFailureReasonErrorKey: XULocalizedString("Could not read synchronization change data.", inBundle: XUCoreFramework.bundle)
				])
			}
			
			guard (try? originalData.write(to: _currentComputerSyncURL, options: [.atomic])) != nil else {
				throw NSError(domain: XUDocumentSyncManagerErrorDomain, code: 0, userInfo: [
					NSLocalizedFailureReasonErrorKey: XULocalizedString("Could not copy synchronization change data to the cloud.", inBundle: XUCoreFramework.bundle)
				])
			}
			
			self.applicationSyncManager.didUpdateFile(at: _currentComputerSyncURL)
			
			XU_PERFORM_BLOCK_ON_MAIN_THREAD({ 
				self.delegate?.documentSyncManagerDidSuccessfullyFinishSynchronization(self)
			})
		} catch let error as NSError {
			XULog("\(self) - failed saving sync managed object context \(error)")
			
			XU_PERFORM_BLOCK_ON_MAIN_THREAD({ 
				self.delegate?.documentSyncManager(self, didFailToSaveSynchronizationContextWithError: error)
			})
		}
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
	
	/// This method removes old sync changes. This is done by iterating the time 
	/// stamps folder and finding the lowest timestamp available. We can delete 
	/// all changesets before that timestamps, since all other clients have 
	/// definitely seen these changes already.
	///
	/// If no timestamp is found, we simply have no clients so far and can delete
	/// all changesets.
 	private func _performSyncCleanup() {
		guard let timestampsFolderURL = XUSyncManagerPathUtilities.timestampsDirectoryURLForSyncManager(self.applicationSyncManager, computerID: XU_SYNC_DEVICE_ID(), andDocumentUUID: self.uuid) else {
			return
		}
		
		var latestTimeStamp = TimeInterval(CGFloat.greatestFiniteMagnitude)
		let contents = FileManager.default.contentsOfDirectory(at: timestampsFolderURL)
		for timestampURL in contents {
			if timestampURL.pathExtension !=  "plist" {
				continue
			}
	
			guard let dict = NSDictionary(contentsOf: timestampURL) as? XUJSONDictionary else {
				continue
			}
			
			let timestamp = dict.double(forKey: XUDocumentLastProcessedChangeSetKey)
			if timestamp == 0.0 {
				continue
			}
	
			latestTimeStamp = min(timestamp, latestTimeStamp)
		}
	
		// Due to a few issues with immediately deleting the sync change sets, we're
		// keeping them for 24 hours just to be sure.
		//
		// The main issue here is the following scenario:
		//
		// 1) Device A creates a document, uploads whole store.
		// 2) Device B downloads the whole store, opens it.
		// 3) Device A in the meantime creates a new change, which is, however,
		//		immediately deleted, since there are no registered observers.
		//
		// We're trying to prevent this by immediately writing a timestamp to the
		// Device A's sync folder, but the changes may take some time to propagate.
		// So generally speaking, this is just to be safe rather than sorry.
	
		latestTimeStamp = min(latestTimeStamp, Date.timeIntervalSinceReferenceDate - XUTimeInterval.day)
	
		// Get all change sets.
		let syncChangeSets = XUSyncChangeSet.allChangeSets(inContext: self.syncManagedObjectContext, withTimestampNewerThan: 0.0)
		for changeSet in syncChangeSets {
			if changeSet.timestamp < latestTimeStamp {
				// Delete
				for change in changeSet.changes {
					self.syncManagedObjectContext.delete(change)
				}
	
				XULog("Deleting changeSet with timestamp [\(changeSet.timestamp)]")
				
				self.syncManagedObjectContext.delete(changeSet)
			}
		}
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
	
	/// Performs the actual synchronization. This is done by enumerating existing
	/// folders representing computers that upload sync changes.
	///
	/// For each computer then, a new MOC is created and the database is read as
	/// read-only for performance reasons.
	///
	/// All changes are then processed on main thread. (THIS IS IMPORTANT.)
 	private func _synchronizeAndReturnError() throws {
	
		/// This is an objectCache that allows quick object lookup by ID. We're 
		/// keeping one per entire sync since it's likely that recently used items 
		/// will be reused.
		var objectCache: [String : XUManagedObject] = [:]
	
		guard let documentFolder = XUSyncManagerPathUtilities.documentFolderURLForSyncManager(self.applicationSyncManager, andDocumentUUID: self.uuid) else {
			throw NSError(domain: XUDocumentSyncManagerErrorDomain, code: 0, userInfo: [
				NSLocalizedFailureReasonErrorKey: XULocalizedFormattedString("Can't find synchronization folder for document %@.", self.uuid)
			])
		}
		
		for computerURL in FileManager.default.contentsOfDirectory(at: documentFolder) {
			// The computerURL is a folder that contains computer-specific sync data
			let computerID = computerURL.lastPathComponent
			guard computerID != ".DS_Store", !computerID.isEmpty else {
				// Ignore DS_Store
				continue
			}
	
			if computerID == XU_SYNC_DEVICE_ID() {
				// Ignore our own sync data
				continue
			}
	
			do {
				try self._synchronizeWithComputerWithID(computerID, objectCache: &objectCache)
			} catch let error as NSError {
				XU_PERFORM_BLOCK_ON_MAIN_THREAD({ 
					self.delegate?.documentSyncManager(self, didEncounterNonFatalErrorDuringSynchronization: error)
				})
			}
		}
	}
	
	/// This method syncs with data from computer with ID and returns error. If 
	/// the error is non-fatal, this method will still return YES. NO is returned 
	/// on fatal errors, e.g. when we fail to initialize a new managed object, etc.
	///
	/// The minor errors are reported to the delegate.
	private func _synchronizeWithComputerWithID(_ computerID: String, objectCache objCache: inout [String : XUManagedObject]) throws {
		XULog("\(self.uuid) Starting synchronization with computer \(computerID).")
		
		let ctx = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
		let coordinator = NSPersistentStoreCoordinator(managedObjectModel: _syncModel)
		guard let fileURL = XUSyncManagerPathUtilities.persistentSyncStorageURLForSyncManager(self.applicationSyncManager, computerID: computerID, andDocumentUUID: self.uuid) else {
			XULog("\(self.uuid) Can't get persistent sync storage URL for \(computerID).")
			throw NSError(domain: XUDocumentSyncManagerErrorDomain, code: 0, userInfo: [
				NSLocalizedFailureReasonErrorKey: XULocalizedFormattedString("Can't find synchronization folder for computer %@.", computerID)
			])
		}
	
		_ = try? self.applicationSyncManager.startDownloading(itemAt: fileURL)
	
		let options = [
			NSReadOnlyPersistentStoreOption: true,
			NSMigratePersistentStoresAutomaticallyOption: false
		]
		
		if !(fileURL as NSURL).checkResourceIsReachableAndReturnError(nil) {
			XULog("\(self.uuid) Changes from \(computerID) are not synced yet.")
			throw NSError(domain: XUDocumentSyncManagerErrorDomain, code: 0, userInfo: [
				NSLocalizedFailureReasonErrorKey: XULocalizedFormattedString("Synchronization changes from computer %@ haven't been downloaded yet.", computerID)
			])
		}
	
		_ = try coordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: fileURL, options: options)
		ctx.persistentStoreCoordinator = coordinator
	
		// We need to find out which change was last seen by this computer
		guard let infoDictURL = XUSyncManagerPathUtilities.persistentSyncStorageInfoURLForSyncManager(self.applicationSyncManager, computerID: XU_SYNC_DEVICE_ID(), andDocumentUUID: self.uuid) else {
			throw NSError(domain: XUDocumentSyncManagerErrorDomain, code: 0, userInfo: [
				NSLocalizedFailureReasonErrorKey: XULocalizedFormattedString("Can't find synchronization folder for computer %@.", computerID)
			])
		}
		try self.applicationSyncManager.createDirectory(at: infoDictURL.deletingLastPathComponent())
	
		/// We don't care if the dictionary exists or not - if it doesn't, we'll
		/// include all the changes.
		let infoDict = NSDictionary(contentsOf: infoDictURL) as? XUJSONDictionary
		let lastTimestampSeen = infoDict?.double(forKey: XUDocumentLastProcessedChangeSetKey) ?? 0.0
	
		// If this is the first sync, lastTimestampSeen will be 0.0, hence 
		// everything will be applied.
	
		let changeSets = XUSyncChangeSet.allChangeSets(inContext: ctx, withTimestampNewerThan: lastTimestampSeen)
		if changeSets.count  == 0 {
			// A likely scenario -> bail out
			XULog("\(computerID) - No change sets.")
			return
		}
		
		XULog("\(computerID) - \(changeSets.count) change sets.")
	
		var blockError: NSError? = nil
		
		XU_PERFORM_BLOCK_ON_MAIN_THREAD {
			let errors: [NSError] = []
			for changeSet in changeSets {
				XULog("\(self.uuid) Processing change set \(changeSet.timestamp) for \(computerID).")
				
				let changeSetErros = self._apply(changeSet: changeSet, withObjectCache: &objCache)
				
				if errors.count > 0 {
					XULog("\(self.uuid) Applying change set \(changeSet.timestamp) from \(computerID) failed due to errors \(changeSetErros).")
				}
			}
			
			if !errors.isEmpty {
				blockError = XUCompoundError(domain: XUDocumentSyncManagerErrorDomain, localizedFailureReason: XULocalizedString("Failing to apply change sets.", inBundle: XUCoreFramework.bundle), andErrors: errors)
			}
		}
	
		// Since the array is sorted by timestamps, we can just take the last one
		let maxTimestamp = changeSets.last!.timestamp
		
		let newInfoDict: NSDictionary = [ XUDocumentLastProcessedChangeSetKey: maxTimestamp ]
	
		// Since each device has its own file, we don't need to lock the file 
		// anyhow, or worry about some collision issues.
		newInfoDict.write(to: infoDictURL, atomically: true)
		self.applicationSyncManager.didUpdateFile(at: infoDictURL)
		
		/// We will mark the sync changes as seen anyway, since we'd run into
		/// them in the next sync cycle anyway.
		if blockError != nil {
			throw blockError!
		}
	}

	/// Inits the document sync manager with fileURL, appSyncManager and UUID.
	/// Returns nil, if iCloud is off.
	public init(managedObjectContext: NSManagedObjectContext, applicationSyncManager appSyncManager: XUApplicationSyncManager, andUUID UUID: String) throws {
		self.applicationSyncManager = appSyncManager
		self.uuid = UUID

		/// We're running all syncing on the main thread.
		self.syncManagedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
		_syncModel = NSManagedObjectModel.mergedModel(from: [ XUCoreFramework.bundle ])!
		_syncStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: _syncModel)
		
		_currentComputerTempSyncURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(NSUUID().uuidString + ".sql")
		
		self.managedObjectContext = managedObjectContext
		self.managedObjectContext.documentSyncManager = self
	
		if let deviceFolderURL = XUSyncManagerPathUtilities.deviceSpecificFolderURLForSyncManager(appSyncManager, computerID: XU_SYNC_DEVICE_ID(), andDocumentUUID: UUID) {
			do {
				try appSyncManager.createDirectory(at: deviceFolderURL)
			} catch let error as NSError {
				XULog("\(self) - failed to create device specific folder URL \(deviceFolderURL), error \(error)")
			}
		}
	
		guard let persistentStoreURL = XUSyncManagerPathUtilities.persistentSyncStorageURLForSyncManager(appSyncManager, computerID: XU_SYNC_DEVICE_ID(), andDocumentUUID: UUID) else {
			throw NSError(domain: XUDocumentSyncManagerErrorDomain, code: 0, userInfo: [
				NSLocalizedFailureReasonErrorKey: XULocalizedFormattedString("Can't find sync folder for document %@.", UUID)
			])
		}
	
		try appSyncManager.createDirectory(at: persistentStoreURL.deletingLastPathComponent())
	
		let dict = [
			NSSQLitePragmasOption: [ "journal_mode" : "DELETE" ],
			NSReadOnlyPersistentStoreOption: false,
			NSMigratePersistentStoresAutomaticallyOption: true
		] as [String : Any]
		
		_currentComputerSyncURL = persistentStoreURL
		
		// It doesn't have to exist.
		_ = try? FileManager.default.copyItem(at: _currentComputerSyncURL, to: _currentComputerTempSyncURL)
		
		try _syncStoreCoordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: _currentComputerTempSyncURL, options: dict)
		
		self.syncManagedObjectContext.persistentStoreCoordinator = _syncStoreCoordinator
	
		NotificationCenter.default.addObserver(self, selector: #selector(_createSyncChanges(_:)), name: NSNotification.Name.NSManagedObjectContextWillSave, object: managedObjectContext)
		NotificationCenter.default.addObserver(self, selector: #selector(_startSync(_:)), name: NSNotification.Name.NSManagedObjectContextDidSave, object: managedObjectContext)
	}
	
	/// Starts synchronization with other devices.
	open func startSynchronizing(withCompletionHandler completionHandler: @escaping (Bool, NSError?) -> Void) {
		_synchronizationLock.lock()
		guard !_isSyncing else {
			// Already syncing
			_synchronizationLock.unlock()
			completionHandler(false, NSError(domain: XUDocumentSyncManagerErrorDomain, code: 0, userInfo: [
				NSLocalizedFailureReasonErrorKey: XULocalizedString("Synchronization is already in progress.", inBundle: XUCoreFramework.bundle)
			]))
			return
		}
		
		guard !self.applicationSyncManager.isDownloadingData else {
			// App manager is downloading data.
			_synchronizationLock.unlock()
			completionHandler(false, NSError(domain: XUDocumentSyncManagerErrorDomain, code: 0, userInfo: [
				NSLocalizedFailureReasonErrorKey: XULocalizedString("Synchronization data is being downloaded.", inBundle: XUCoreFramework.bundle)
			]))
			return
		}
	
		_isSyncing = true
		_synchronizationLock.unlock()
	
		#if os(iOS)
			_syncBackgroundTaskIdentifier = UIApplication.shared.beginBackgroundTask(withName: "XUDocumentSyncManager.Sync", expirationHandler: {
				if self._syncBackgroundTaskIdentifier == UIBackgroundTaskInvalid {
					return
				}
				
				// The sync hasn't finished yet. Inform the user.
				self._syncBackgroundTaskIdentifier = UIBackgroundTaskInvalid

				let notification = UILocalNotification()
				notification.alertTitle = XULocalizedFormattedString("%@ couldn't finish synchronization in the background.", ProcessInfo.processInfo.processName)
				notification.alertBody =  XULocalizedFormattedString("Please switch back to %@ so that the synchronization can finish.", ProcessInfo.processInfo.processName)
				notification.fireDate = NSDate(timeIntervalSinceNow: 1.0) as Date
		
				UIApplication.shared.scheduleLocalNotification(notification)
			})
		#endif
	
		XU_PERFORM_BLOCK_ASYNC {
			var error: NSError?
			do {
				try self._synchronizeAndReturnError()
			} catch let err as NSError {
				error = err
			}
			
			self._synchronizationLock.lock()
			self._isSyncing = false
			self._synchronizationLock.unlock()
	
			XU_PERFORM_BLOCK_ON_MAIN_THREAD({ 
				#if os(iOS)
					UIApplication.shared.endBackgroundTask(self._syncBackgroundTaskIdentifier)
					self._syncBackgroundTaskIdentifier = UIBackgroundTaskInvalid
				#endif
				
				completionHandler(error == nil, error)
			})
		}
	}
	
	/// Uploads the entire document to the cloud.
	open func uploadEntireDocument(fromURL fileURL: URL, withCompletionHandler completionHandler: @escaping (Bool, NSError?) -> Void) {
		assert(Thread.isMainThread, "This methos must be called from the main thread!")
		
		// The _isUploadingEntireDocument flag is only changed from main thread
		// so no locks are necessary
		if _isUploadingEntireDocument {
			completionHandler(false, NSError(domain: XUDocumentSyncManagerErrorDomain, code: 0, userInfo: [
				NSLocalizedFailureReasonErrorKey: XULocalizedString("An upload operation is already in progress.", inBundle: XUCoreFramework.bundle)
			]))
			return
		}
	
		_isUploadingEntireDocument = true
	
		// We need to figure out which is last change set in our sync MOC, so that
		// we can mark the upload as including these change sets. Why? When the other
		// device downloads the whole-store, it mustn't apply any changes to it that
		// have already been included in the whole-store upload
		//
		// Since we perform all syncing on main thread, it is guaranteed that the
		// lastChangeSet will indeed be last.
		let lastChangeSet: XUSyncChangeSet?
		do {
			lastChangeSet = try XUSyncChangeSet.newestChangeSet(inContext: self.syncManagedObjectContext)
		} catch let error as NSError {
			completionHandler(false, error)
			_isUploadingEntireDocument = false
			return
		}
	
		// We don't care if lastChangeSet == nil, since that will simply make
		// lastChangeSetTimestamp == 0.0 which works just fine
		let lastChangeSetTimestamp = lastChangeSet?.timestamp ?? 0.0
	
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
		
		guard let entireDocumentFolderURL = XUSyncManagerPathUtilities.entireDocumentFolderURLForSyncManager(self.applicationSyncManager, computerID: XU_SYNC_DEVICE_ID(), andDocumentUUID: self.uuid) else {
			let error = NSError(domain: XUDocumentSyncManagerErrorDomain, code: 0, userInfo: [
				NSLocalizedFailureReasonErrorKey: XULocalizedFormattedString("Can't find synchronization folder for document %@.", self.uuid)
			])
			completionHandler(false, error)
			_isUploadingEntireDocument = false
			return
		}
	
		XU_PERFORM_BLOCK_ASYNC {
			let coordinator = NSFileCoordinator(filePresenter: nil)
			var err: NSError?
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
					err = error
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
					err = NSError(domain: XUDocumentSyncManagerErrorDomain, code: 0, userInfo: [
						NSLocalizedFailureReasonErrorKey: XULocalizedString("Could not save upload metadata.", inBundle: XUCoreFramework.bundle)
					])
					return
				}
	
				self.applicationSyncManager.didUpdateFile(at: configURL)
				success = true
			})
	
			XU_PERFORM_BLOCK_ON_MAIN_THREAD({ 
				completionHandler(success, err)
				self._isUploadingEntireDocument = false
			})
		}
	}
	
}


private let NSManagedObjectContextXUSyncManagerKey: AnyObject = "NSManagedObjectContextXUSyncManager" as AnyObject

public extension NSManagedObjectContext {
	
	public var documentSyncManager: XUDocumentSyncManager? {
		get {
			return objc_getAssociatedObject(self, Unmanaged.passUnretained(NSManagedObjectContextXUSyncManagerKey).toOpaque()) as? XUDocumentSyncManager
		}
		set {
			objc_setAssociatedObject(self, Unmanaged.passUnretained(NSManagedObjectContextXUSyncManagerKey).toOpaque(), newValue, .OBJC_ASSOCIATION_RETAIN)
		}
	}
	
}
