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
	func documentSyncManager(manager: XUDocumentSyncManager, didFailToSaveSynchronizationContextWithError error: NSError)

	/// Optional method that informs the delegate that the manager has encountered
	/// an error during synchronization and the error isn't fatal.
	func documentSyncManager(manager: XUDocumentSyncManager, didEncounterNonFatalErrorDuringSynchronization error: NSError)

	/// Optional method that informs the delegate that the manager has finished
	/// synchronization.
	func documentSyncManagerDidSuccessfullyFinishSynchronization(manager: XUDocumentSyncManager)

}

public extension XUDocumentSyncManagerDelegate {
	public func documentSyncManager(manager: XUDocumentSyncManager, didEncounterNonFatalErrorDuringSynchronization error: NSError) {}
	public func documentSyncManagerDidSuccessfullyFinishSynchronization(manager: XUDocumentSyncManager) {}
}


private let XUDocumentSyncManagerErrorDomain = "XUDocumentSyncManagerErrorDomain"

private let XUDocumentLastUploadDateKey = "XUDocumentLastUploadDate"
private let XUDocumentLastSyncChangeSetTimestampKey = "XUDocumentLastSyncChangeSetTimestamp"
private let XUDocumentNameKey = "XUDocumentName"

private let XUDocumentLastProcessedChangeSetKey = "XUDocumentLastProcessedChangeSet"



public class XUDocumentSyncManager {
	
	/// Synchronously downloads document with document ID to URL and returns error,
	/// if the download wasn't successful.
	///
	/// The returned NSURL points to the actual document.
	public class func downloadDocumentWithID(documentID: String, forApplicationSyncManager appSyncManager: XUApplicationSyncManager, toURL fileURL: NSURL) throws -> NSURL {
		
		guard let config = self.URLOfNewestEntireDocumentWithUUID(documentID, forApplicationSyncManager: appSyncManager) else {
			
			XULog("Document sync manager was unable to find whole-store upload for document with ID \(documentID)")
			
			throw NSError(domain: XUDocumentSyncManagerErrorDomain, code: 0, userInfo: [
				NSLocalizedFailureReasonErrorKey : XULocalizedString("Cannot find such document. Check back later, it might not have synced through.")
			])
		}
		
		var documentURL: NSURL?
		var error: NSError?
		
		let coordinator = NSFileCoordinator(filePresenter: nil)
		coordinator.coordinateReadingItemAtURL(config.accountURL, options: .WithoutChanges, error: &error, byAccessor: { (newURL) in
			let infoFileURL = config.accountURL.URLByDeletingLastPathComponent!.URLByAppendingPathComponent("Info.plist")
			guard let accountDict = NSDictionary(contentsOfURL: infoFileURL) as? XUJSONDictionary else {
				error = NSError(domain: XUDocumentSyncManagerErrorDomain, code: 0, userInfo: [
					NSLocalizedFailureReasonErrorKey : XULocalizedString("Cannot open document metadata file.")
				])
				return
			}
		
			guard let documentName = accountDict[XUDocumentNameKey] as? String else {
				error = NSError(domain: XUDocumentSyncManagerErrorDomain, code: 0, userInfo: [
					NSLocalizedFailureReasonErrorKey : XULocalizedString("Metadata file doesn't contain required information.")
				])
				return
			}
		
			NSFileManager.defaultManager().createDirectoryAtURL(fileURL)
		
			let remoteDocumentURL = config.accountURL.URLByAppendingPathComponent(documentName)
			let localDocumentURL = fileURL.URLByAppendingPathComponent(documentName)
		
			do {
				try NSFileManager.defaultManager().copyItemAtURL(remoteDocumentURL, toURL: localDocumentURL)
				
				documentURL = localDocumentURL
				
				// We need to copy the sync timestamp
				let syncInfoURL = XUSyncManagerPathUtilities.persistentSyncStorageInfoURLForSyncManager(appSyncManager, computerID: config.computerID, andDocumentUUID: documentID)
				
				try appSyncManager.createDirectoryAtURL(syncInfoURL.URLByDeletingLastPathComponent!)
				
				let timeStamp = accountDict.doubleForKey(XUDocumentLastUploadDateKey)
				let syncInfoDict: NSDictionary = [
					XUDocumentLastProcessedChangeSetKey: timeStamp
				]
				
				syncInfoDict.writeToURL(syncInfoURL, atomically: true)
				appSyncManager.didUpdateFileAtURL(syncInfoURL)
			} catch let localError as NSError {
				error = localError
			}
		})
		
		if error != nil {
			throw error!
		}
		
		return documentURL!
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
	public class func URLOfNewestEntireDocumentWithUUID(documentID: String, forApplicationSyncManager appSyncManager: XUApplicationSyncManager) -> (accountURL: NSURL, computerID: String)? {
		guard let folderURL = XUSyncManagerPathUtilities.documentFolderURLForSyncManager(appSyncManager, andDocumentUUID: documentID) else {
			return nil
		}
		
		let coordinator = NSFileCoordinator(filePresenter: nil)
		var newestURL: NSURL?
		var newestDate: NSDate?
		var newestComputerID: String?
		
		coordinator.coordinateReadingItemAtURL(folderURL, options: .WithoutChanges, error:nil, byAccessor: { (newURL) in
			let contents = NSFileManager.defaultManager().contentsOfDirectoryAtURL(newURL)
			for computerURL in contents {
				guard let computerID = computerURL.lastPathComponent where computerID != ".DS_Store" else {
					continue
				}
			
				let infoFileURL = XUSyncManagerPathUtilities.entireDocumentInfoFileURLForSyncManager(appSyncManager, computerID: computerID, andDocumentUUID: documentID)
				
				guard let dict = NSDictionary(contentsOfURL: infoFileURL) as? XUJSONDictionary else {
					_ = try? appSyncManager.startDownloadingItemAtURL(infoFileURL)
					continue
				}
			
				let timeInterval = dict.doubleForKey(XUDocumentLastUploadDateKey)
				if timeInterval == 0.0 {
					continue
				}
				
				let fileDate = NSDate(timeIntervalSinceReferenceDate: timeInterval)
				if newestDate == nil || fileDate.compare(newestDate!) == .OrderedDescending {
					newestDate = fileDate
					let wholeStoreURL = XUSyncManagerPathUtilities.entireDocumentFolderURLForSyncManager(appSyncManager, computerID: computerID, andDocumentUUID: documentID)
					newestURL = wholeStoreURL.URLByAppendingPathComponent("Document")
			
					newestComputerID = computerID;
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
	public let applicationSyncManager: XUApplicationSyncManager
	
	/// Delegate.
	public weak var delegate: XUDocumentSyncManagerDelegate?
	
	/// Main object context that was passed in the initializer.
	public let managedObjectContext: NSManagedObjectContext
	
	/// MOC used for sync changes.
	public let syncManagedObjectContext: NSManagedObjectContext
	
	/// UUID of the document.
	public let UUID: String


	/// URL to the CoreData file that contains sync changes.
	private var _currentComputerSyncURL: NSURL!
	
	/// URL to the CoreData file that we're actually writing changes (in temp
	/// dir).
	private let _currentComputerTempSyncURL: NSURL
	
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
	@warn_unused_result
	private func _applyChangeSet(changeSet: XUSyncChangeSet, inout withObjectCache objCache: [String : XUManagedObject]) -> [NSError] {
		let changes = changeSet.changes
	
		var errors: [NSError] = []
		
		// We need to apply insertion changes first since other changes may include
		// relationship changes, which include these entities
		let insertionChanges = changes.filter({ $0 is XUInsertionSyncChange }) as! [XUInsertionSyncChange]
		for change in insertionChanges {
			XULog("Applying insertion change [\(change.insertedEntityName)]")
			
			guard let entityDescription = NSEntityDescription.entityForName(change.insertedEntityName, inManagedObjectContext: self.managedObjectContext) else {
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
			
			let fetchRequest = NSFetchRequest(entityName: change.objectEntityName)
			fetchRequest.predicate = NSPredicate(format: "ticdsSyncID == %@", change.objectSyncID)
			
			obj = (try? self.managedObjectContext.executeFetchRequest(fetchRequest))?.first as? XUManagedObject
			if obj != nil {
				XULog("Object with ID \(obj.syncUUID) already exists!")
				continue
			}
	
			obj = cl.init(entity: entityDescription, insertIntoManagedObjectContext: self.managedObjectContext, asResultOfSyncAction: true)
			
			let exceptionHandler = XUExceptionHandler()
			
			let attributes = change.attributes
			for (key, value) in attributes {
				obj.isApplyingSyncChange = true
				
				exceptionHandler.performBlock({ 
					obj.setValue(value, forKey: key)
				}, withCatchHandler: { (exception) in
					XULog("Failed setting \(value) for key \(key) on \(change.insertedEntityName) - \(exception).")
				}, andFinallyBlock: { 
					obj.isApplyingSyncChange = false
				})
			}
	
			XUManagedObject.noticeSyncInsertionOfObjectWithID(obj.syncUUID)
			objCache[obj.syncUUID] = obj
		}
	
		// Done with insertion - now get the remaining changes and apply them
		let otherChanges = changes.filter({ !($0 is XUInsertionSyncChange) })
		
		for change in otherChanges {
			XULog("Applying change [\(change.entity.name.descriptionWithDefaultValue())]")
			
			var obj: XUManagedObject! = objCache[change.objectSyncID]
			if obj == nil {
				let fetchRequest = NSFetchRequest(entityName: change.objectEntityName)
				fetchRequest.predicate = NSPredicate(format: "ticdsSyncID == %@", change.objectSyncID)
				obj = (try? self.managedObjectContext.executeFetchRequest(fetchRequest))?.first as? XUManagedObject
			}
		
			if obj == nil {
				errors.append(NSError(domain: XUDocumentSyncManagerErrorDomain, code: 0, userInfo: [
					NSLocalizedFailureReasonErrorKey: XULocalizedFormattedString("Cannot find entity with ID %@", change.objectSyncID)
				]))
				continue
			}
		
			obj.applySyncChange(change)
		}
		
		return errors
	}

	/// This method is an observer for NSManagedObjectContextWillSaveNotification.
	@objc private func _createSyncChanges(aNotif: NSNotification) {
		if !NSThread.isMainThread() {
			XU_PERFORM_BLOCK_ON_MAIN_THREAD { self._createSyncChanges(aNotif) }
			return
		}
	
		XULog("\(self) - managed object context will save, creating sync changes.")
	
		var changes: [XUSyncChange] = []
		changes += self._createSyncChangesForObjects(self.managedObjectContext.insertedObjects)
		changes += self._createSyncChangesForObjects(self.managedObjectContext.updatedObjects)
		changes += self._createSyncChangesForObjects(self.managedObjectContext.deletedObjects)
	
		if changes.count == 0 {
			// Do not create anything.
			XU_PERFORM_BLOCK_ON_MAIN_THREAD {
				self.delegate?.documentSyncManagerDidSuccessfullyFinishSynchronization(self)
			}
			
			// Don't even do sync cleanup, we'll simply do it next time
			return
		}
	
		// Create a change set.
		_ = XUSyncChangeSet(managedObjectContext: self.syncManagedObjectContext, andChanges: changes)
		XULog("\(self) - created change set with \(changes.count) changes")
	
		self._performSyncCleanup()
	
		do {
			try self.syncManagedObjectContext.save()
			
			// The context is saved in a temporary location - copy it over to the 
			// cloud.
			guard let originalData = NSData(contentsOfURL: _currentComputerTempSyncURL) else {
				throw NSError(domain: XUDocumentSyncManagerErrorDomain, code: 0, userInfo: [
					NSLocalizedFailureReasonErrorKey: XULocalizedString("Could not read synchronization change data.")
				])
			}
			
			guard originalData.writeToURL(_currentComputerSyncURL, atomically: true) else {
				throw NSError(domain: XUDocumentSyncManagerErrorDomain, code: 0, userInfo: [
					NSLocalizedFailureReasonErrorKey: XULocalizedString("Could not copy synchronization change data to the cloud.")
				])
			}
			
			self.applicationSyncManager.didUpdateFileAtURL(_currentComputerSyncURL)
			
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
	
	private func _createSyncChangesForObjects(objects: Set<NSManagedObject>) -> [XUSyncChange] {
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
		guard let timestampsFolderURL = XUSyncManagerPathUtilities.timestampsDirectoryURLForSyncManager(self.applicationSyncManager, computerID: XU_SYNC_DEVICE_ID(), andDocumentUUID: self.UUID) else {
			return
		}
		
		var latestTimeStamp = NSTimeInterval(CGFloat.max)
		let contents = NSFileManager.defaultManager().contentsOfDirectoryAtURL(timestampsFolderURL)
		for timestampURL in contents {
			if timestampURL.pathExtension !=  "plist" {
				continue
			}
	
			guard let dict = NSDictionary(contentsOfURL: timestampURL) as? XUJSONDictionary else {
				continue
			}
			
			let timestamp = dict.doubleForKey(XUDocumentLastProcessedChangeSetKey)
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
	
		latestTimeStamp = min(latestTimeStamp, NSDate.timeIntervalSinceReferenceDate() - XUTimeInterval.day)
	
		// Get all change sets.
		let syncChangeSets = XUSyncChangeSet.allChangeSetsInManagedObjectContext(self.syncManagedObjectContext, withTimestampNewerThan: 0.0)
		for changeSet in syncChangeSets {
			if changeSet.timestamp < latestTimeStamp {
				// Delete
				for change in changeSet.changes {
					self.syncManagedObjectContext.deleteObject(change)
				}
	
				XULog("Deleting changeSet with timestamp [\(changeSet.timestamp)]")
				
				self.syncManagedObjectContext.deleteObject(changeSet)
			}
		}
	}
	
	/// This method is an observer for NSManagedObjectContextWillSaveNotification.
	/// We start a sync after each save.
	@objc private func _startSync(aNotif: NSNotification) {
		self.startSynchronizingWithCompletionHandler { (success, error) in
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
	
		guard let documentFolder = XUSyncManagerPathUtilities.documentFolderURLForSyncManager(self.applicationSyncManager, andDocumentUUID: self.UUID) else {
			throw NSError(domain: XUDocumentSyncManagerErrorDomain, code: 0, userInfo: [
				NSLocalizedFailureReasonErrorKey: XULocalizedFormattedString("Can't find synchronization folder for document %@.", self.UUID)
			])
		}
		
		for computerURL in NSFileManager.defaultManager().contentsOfDirectoryAtURL(documentFolder) {
			// The computerURL is a folder that contains computer-specific sync data
	
			guard let computerID = computerURL.lastPathComponent where computerID != ".DS_Store" else {
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
	private func _synchronizeWithComputerWithID(computerID: String, inout objectCache objCache: [String : XUManagedObject]) throws {
		XULog("\(self.UUID) Starting synchronization with computer \(computerID).")
		
		let ctx = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
		let coordinator = NSPersistentStoreCoordinator(managedObjectModel: _syncModel)
		guard let fileURL = XUSyncManagerPathUtilities.persistentSyncStorageURLForSyncManager(self.applicationSyncManager, computerID: computerID, andDocumentUUID: self.UUID) else {
			XULog("\(self.UUID) Can't get persistent sync storage URL for \(computerID).")
			throw NSError(domain: XUDocumentSyncManagerErrorDomain, code: 0, userInfo: [
				NSLocalizedFailureReasonErrorKey: XULocalizedFormattedString("Can't find synchronization folder for computer %@.", computerID)
			])
		}
	
		
		
		_ = try? self.applicationSyncManager.startDownloadingItemAtURL(fileURL)
	
		let options = [
			NSReadOnlyPersistentStoreOption: true,
			NSMigratePersistentStoresAutomaticallyOption: false
		]
		
		if !fileURL.checkResourceIsReachableAndReturnError(nil) {
			XULog("\(self.UUID) Changes from \(computerID) are not synced yet.")
			throw NSError(domain: XUDocumentSyncManagerErrorDomain, code: 0, userInfo: [
				NSLocalizedFailureReasonErrorKey: XULocalizedFormattedString("Synchronization changes from computer %@ haven't been downloaded yet.", computerID)
			])
		}
	
		_ = try coordinator.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: fileURL, options: options)
		ctx.persistentStoreCoordinator = coordinator
	
		// We need to find out which change was last seen by this computer
		let infoDictURL = XUSyncManagerPathUtilities.persistentSyncStorageInfoURLForSyncManager(self.applicationSyncManager, computerID: XU_SYNC_DEVICE_ID(), andDocumentUUID: self.UUID)
		try self.applicationSyncManager.createDirectoryAtURL(infoDictURL.URLByDeletingLastPathComponent!)
	
		/// We don't care if the dictionary exists or not - if it doesn't, we'll
		/// include all the changes.
		let infoDict = NSDictionary(contentsOfURL: infoDictURL) as? XUJSONDictionary
		let lastTimestampSeen = infoDict?.doubleForKey(XUDocumentLastProcessedChangeSetKey) ?? 0.0
	
		// If this is the first sync, lastTimestampSeen will be 0.0, hence 
		// everything will be applied.
	
		let changeSets = XUSyncChangeSet.allChangeSetsInManagedObjectContext(ctx, withTimestampNewerThan: lastTimestampSeen)
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
				XULog("\(self.UUID) Processing change set \(changeSet.timestamp) for \(computerID).")
				
				let changeSetErros = self._applyChangeSet(changeSet, withObjectCache: &objCache)
				
				if errors.count > 0 {
					XULog("\(self.UUID) Applying change set \(changeSet.timestamp) from \(computerID) failed due to errors \(changeSetErros).")
				}
			}
			
			if !errors.isEmpty {
				blockError = XUCompoundError(domain: XUDocumentSyncManagerErrorDomain, localizedFailureReason: XULocalizedString("Failing to apply change sets."), andErrors: errors)
			}
		}
	
		// Since the array is sorted by timestamps, we can just take the last one
		let maxTimestamp = changeSets.last!.timestamp
		
		let newInfoDict: NSDictionary = [ XUDocumentLastProcessedChangeSetKey: maxTimestamp ]
	
		// Since each device has its own file, we don't need to lock the file 
		// anyhow, or worry about some collision issues.
		newInfoDict.writeToURL(infoDictURL, atomically: true)
		self.applicationSyncManager.didUpdateFileAtURL(infoDictURL)
		
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
		self.UUID = UUID

		/// We're running all syncing on the main thread.
		self.syncManagedObjectContext = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
		_syncModel = NSManagedObjectModel.mergedModelFromBundles([ XUCoreBundle ])!
		_syncStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: _syncModel)
		
		_currentComputerTempSyncURL = NSURL(fileURLWithPath: NSTemporaryDirectory()).URLByAppendingPathComponent(String.UUIDString + ".sql")
		
		self.managedObjectContext = managedObjectContext
		self.managedObjectContext.documentSyncManager = self
	
		if let deviceFolderURL = XUSyncManagerPathUtilities.deviceSpecificFolderURLForSyncManager(appSyncManager, computerID: XU_SYNC_DEVICE_ID(), andDocumentUUID: UUID) {
			do {
				try appSyncManager.createDirectoryAtURL(deviceFolderURL)
			} catch let error as NSError {
				XULog("\(self) - failed to create device specific folder URL \(deviceFolderURL), error \(error)")
			}
		}
	
		guard let persistentStoreURL = XUSyncManagerPathUtilities.persistentSyncStorageURLForSyncManager(appSyncManager, computerID: XU_SYNC_DEVICE_ID(), andDocumentUUID: UUID) else {
			throw NSError(domain: XUDocumentSyncManagerErrorDomain, code: 0, userInfo: [
				NSLocalizedFailureReasonErrorKey: XULocalizedFormattedString("Can't find sync folder for document %@.", UUID)
			])
		}
	
		try appSyncManager.createDirectoryAtURL(persistentStoreURL.URLByDeletingLastPathComponent!)
	
		let dict = [
			NSSQLitePragmasOption: [ "journal_mode" : "DELETE" ],
			NSReadOnlyPersistentStoreOption: false,
			NSMigratePersistentStoresAutomaticallyOption: true
		]
		
		_currentComputerSyncURL = persistentStoreURL
		
		// It doesn't have to exist.
		_ = try? NSFileManager.defaultManager().copyItemAtURL(_currentComputerSyncURL, toURL: _currentComputerTempSyncURL)
		
		try _syncStoreCoordinator.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: _currentComputerTempSyncURL, options: dict)
		
		self.syncManagedObjectContext.persistentStoreCoordinator = _syncStoreCoordinator
	
		NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(_createSyncChanges(_:)), name: NSManagedObjectContextWillSaveNotification, object: managedObjectContext)
		NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(_startSync(_:)), name: NSManagedObjectContextDidSaveNotification, object: managedObjectContext)
	}

	/// Starts synchronization with other devices.
	public func startSynchronizingWithCompletionHandler(completionHandler: (Bool, NSError?) -> Void) {
		_synchronizationLock.lock()
		if _isSyncing {
			// Already syncing
			_synchronizationLock.unlock()
			completionHandler(false, NSError(domain: XUDocumentSyncManagerErrorDomain, code: 0, userInfo: [
				NSLocalizedFailureReasonErrorKey: XULocalizedString("Synchronization is already in progress.")
			]))
			return
		}
	
		_isSyncing = true
		_synchronizationLock.unlock()
	
		#if os(iOS)
			_syncBackgroundTaskIdentifier = UIApplication.sharedApplication().beginBackgroundTaskWithName("XUDocumentSyncManager.Sync", expirationHandler: {
				if self._syncBackgroundTaskIdentifier == UIBackgroundTaskInvalid {
					return
				}
				
				// The sync hasn't finished yet. Inform the user.
				self._syncBackgroundTaskIdentifier = UIBackgroundTaskInvalid

				let notification = UILocalNotification()
				notification.alertTitle = XULocalizedFormattedString("%@ couldn't finish synchronization in the background.", NSProcessInfo.processInfo().processName)
				notification.alertBody =  XULocalizedFormattedString("Please switch back to %@ so that the synchronization can finish.", NSProcessInfo.processInfo().processName)
				notification.fireDate = NSDate(timeIntervalSinceNow: 1.0)
		
				UIApplication.sharedApplication().scheduleLocalNotification(notification)
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
					UIApplication.sharedApplication().endBackgroundTask(self._syncBackgroundTaskIdentifier)
					self._syncBackgroundTaskIdentifier = UIBackgroundTaskInvalid
				#endif
				
				completionHandler(error == nil, error)
			})
		}
	}
	
	/// Uploads the entire document to the cloud.
	public func uploadEntireDocumentFromURL(fileURL: NSURL, withCompletionHandler completionHandler: (Bool, NSError?) -> Void) {
		assert(NSThread.isMainThread(), "This methos must be called from the main thread!")
		
		// The _isUploadingEntireDocument flag is only changed from main thread
		// so no locks are necessary
		if _isUploadingEntireDocument {
			completionHandler(false, NSError(domain: XUDocumentSyncManagerErrorDomain, code: 0, userInfo: [
				NSLocalizedFailureReasonErrorKey: XULocalizedString("An upload operation is already in progress.")
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
		let lastChangeSet = XUSyncChangeSet.newestChangeSetInManagedObjectContext(self.syncManagedObjectContext)
	
		// We don't care if lastChangeSet == nil, since that will simply make
		// lastChangeSetTimestamp == 0.0 which works just fine
		let lastChangeSetTimestamp = lastChangeSet?.timestamp ?? 0.0
	
		// Copy the document somewhere else, since the upload may take some time 
		// and changes may be made.
		let tempFolderURL = NSURL(fileURLWithPath: NSTemporaryDirectory()).URLByAppendingPathComponent(String.UUIDString)
		
		NSFileManager.defaultManager().createDirectoryAtURL(tempFolderURL)
	
		do {
			try NSFileManager.defaultManager().copyItemAtURL(fileURL, toURL: tempFolderURL.URLByAppendingPathComponent(fileURL.lastPathComponent!))
		} catch let error as NSError {
			completionHandler(false, error)
			_isUploadingEntireDocument = false
			return
		}
	
		XU_PERFORM_BLOCK_ASYNC {
			let coordinator = NSFileCoordinator(filePresenter: nil)
			var err: NSError?
			var success: Bool = true
			let entireDocumentFolderURL = XUSyncManagerPathUtilities.entireDocumentFolderURLForSyncManager(self.applicationSyncManager, computerID: XU_SYNC_DEVICE_ID(), andDocumentUUID: self.UUID)
			coordinator.coordinateWritingItemAtURL(entireDocumentFolderURL, options: .ForReplacing, error: &err, byAccessor: { (newURL) in
				let docURL = newURL.URLByAppendingPathComponent("Document")
				
				_ = try? self.applicationSyncManager.createDirectoryAtURL(docURL)
	
				let targetURL = docURL.URLByAppendingPathComponent(fileURL.lastPathComponent!)
	
				// Delete the old whole-store
				do {
					_ = try? NSFileManager.defaultManager().removeItemAtURL(targetURL) // It may not exist
					NSFileManager.defaultManager().createDirectoryAtURL(tempFolderURL, withIntermediateDirectories: true)
					
					try NSFileManager.defaultManager().copyItemAtURL(tempFolderURL.URLByAppendingPathComponent(fileURL.lastPathComponent!), toURL: targetURL)
					
					self.applicationSyncManager.didUpdateFileAtURL(targetURL)
				} catch let error as NSError {
					err = error
					success = false
					return
				}
	
				let documentConfig = [
					XUDocumentLastUploadDateKey: NSDate.timeIntervalSinceReferenceDate(),
					XUDocumentLastSyncChangeSetTimestampKey: lastChangeSetTimestamp,
					XUDocumentNameKey: fileURL.lastPathComponent!
				]
	
				let configURL = newURL.URLByAppendingPathComponent("Info.plist")
				if !documentConfig.writeToURL(configURL, atomically: true) {
					success = false
					err = NSError(domain: XUDocumentSyncManagerErrorDomain, code: 0, userInfo: [
						NSLocalizedFailureReasonErrorKey: XULocalizedString("Could not save upload metadata.")
					])
					return
				}
	
				self.applicationSyncManager.didUpdateFileAtURL(configURL)
				success = true
			})
	
			XU_PERFORM_BLOCK_ON_MAIN_THREAD({ 
				completionHandler(success, err)
				self._isUploadingEntireDocument = false
			})
		}
	}
	
}


private let NSManagedObjectContextXUSyncManagerKey: AnyObject = "NSManagedObjectContextXUSyncManager"

public extension NSManagedObjectContext {
	
	public var documentSyncManager: XUDocumentSyncManager? {
		get {
			return objc_getAssociatedObject(self, unsafeAddressOf(NSManagedObjectContextXUSyncManagerKey)) as? XUDocumentSyncManager
		}
		set {
			objc_setAssociatedObject(self, unsafeAddressOf(NSManagedObjectContextXUSyncManagerKey), newValue, .OBJC_ASSOCIATION_RETAIN)
		}
	}
	
}
