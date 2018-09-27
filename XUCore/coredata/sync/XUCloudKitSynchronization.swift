//
//  XUCloudKitSynchronization.swift
//  XUCore
//
//  Created by Charlie Monroe on 3/9/18.
//  Copyright © 2018 Charlie Monroe Software. All rights reserved.
//

import CloudKit
import CoreData
import Foundation

/// Class that performs the synchronization against CloudKit. The
internal final class XUCloudKitSynchronization {
		
	/// Completion handler of the synchronization operation.
	typealias CompletionHandler = (Error?) -> Void
	
	/// Step of the synchronization.
	enum Step {
		
		/// Initial step, nothing going on yet.
		case initial
		
		/// Listing devices that are being synced.
		case listingDevices
		
		/// Downloading changes.
		case downloadingChanges
		
		/// Applying changes.
		case applyingChanges
		
		/// Uploading local changes.
		case uploadingChanges
		
		/// Final step.
		case finished
	}
	
	
	
	/// Change sets pulled from the CloudKit.
	private var _changeSets: [ChangeSet] = []
	
	/// Index of device currently being synchronized.
	private var _currentDeviceIndex: Int = 0
	
	/// Devices against which we're synchronizing.
	private var _devices: [SynchronizedDevice] = []
	
	/// Object cache used. It is a mutable dictionary with UUID -> obj mapping
	/// that is kept during the sync, so that we don't have to perform fetches
	/// unless necessary.
	
	private var _objectCache: [String : XUManagedObject] = [:]
	
	
	/// Completion handler for the entire operation.
	let completionHandler: CompletionHandler
	
	/// Current step of the synchronization.
	private(set) var currentStep: Step = .initial
	
	/// Database we work against.
	let database: CKDatabase
	
	/// Document manager we've initialized.
	let documentManager: XUDocumentSyncManager
	
	
	
	/// Applies changes from changeSet and returns error.
	private func _apply(_ changeSet: XUSyncChangeSet) -> [NSError] {
		let changes = changeSet.changes
		
		var errors: [NSError] = []
		
		// We need to apply insertion changes first since other changes may include
		// relationship changes, which include these entities
		let insertionChanges = changes.compactCast(to: XUInsertionSyncChange.self)
		for change in insertionChanges {
			XULog("Applying insertion change [\(change.insertedEntityName)]")
			
			guard let entityDescription = NSEntityDescription.entity(forEntityName: change.insertedEntityName, in: self.documentManager.managedObjectContext) else {
				let synchronizationError = SynchronizationError(errorCode: .failedToApplyChange, failureReason: XULocalizedFormattedString("Cannot find entity named %@", change.insertedEntityName))
				errors.append(synchronizationError)
				continue
			}
			
			guard let cl = NSClassFromString(entityDescription.managedObjectClassName) as? XUManagedObject.Type else {
				let synchronizationError = SynchronizationError(errorCode: .failedToApplyChange, failureReason: XULocalizedFormattedString("Cannot find class named %@", entityDescription.managedObjectClassName))
				errors.append(synchronizationError)
				continue
			}
			
			let fetchRequest = NSFetchRequest<XUManagedObject>(entityName: change.objectEntityName)
			fetchRequest.predicate = NSPredicate(format: "ticdsSyncID == %@", change.objectSyncID)
			
			if let obj = (try? self.documentManager.managedObjectContext.fetch(fetchRequest))?.first  {
				XULog("Object \(obj.entity.name.descriptionWithDefaultValue()) with ID \(obj.syncUUID) already exists!")
				continue
			}
			
			let obj: XUManagedObject = cl.init(entity: entityDescription, insertInto: self.documentManager.managedObjectContext, asResultOfSyncAction: true)
			
			let attributes = change.attributes
			for (key, value) in attributes {
				obj.isApplyingSyncChange = true
				
				let finalValue: Any?
				if value is NSNull {
					finalValue = nil
				} else {
					finalValue = value
				}
				
				XUExceptionCatcher.perform({
					obj.setValue(finalValue, forKey: key)
				}, withCatchHandler: { (exception) in
					XULog("Failed setting \(value) for key \(key) on \(change.insertedEntityName) - \(exception).")
				}, andFinallyBlock: {
					obj.isApplyingSyncChange = false
				})
			}
			
			XUManagedObject.noticeSyncInsertionOfObject(withID: obj.syncUUID)
			_objectCache[obj.syncUUID] = obj
		}
		
		// Done with insertion - now get the remaining changes and apply them
		let otherChanges = changes.filter({ !($0 is XUInsertionSyncChange) })
		
		for change in otherChanges {
			XULog("Applying change [\(type(of: change))]")
			
			var obj: XUManagedObject! = _objectCache[change.objectSyncID]
			if obj == nil {
				let fetchRequest = NSFetchRequest<XUManagedObject>(entityName: change.objectEntityName)
				fetchRequest.predicate = NSPredicate(format: "ticdsSyncID == %@", change.objectSyncID)
				obj = (try? self.documentManager.managedObjectContext.fetch(fetchRequest))?.first
			}
			
			if obj == nil {
				let synchronizationError = SynchronizationError(errorCode: .failedToApplyChange, failureReason: XULocalizedFormattedString("Cannot find entity with ID %@", change.objectSyncID))
				errors.append(synchronizationError)
				continue
			}
			
			obj.apply(syncChange: change)
		}
		
		return errors
	}
	
	/// Applies changes. Asserts that currentStep is .downloadingChanges and
	/// that Thread.isMainThread.
	private func _applyChanges() {
		assert(Thread.isMainThread)
		assert(self.currentStep == .downloadingChanges)
		self.currentStep = .applyingChanges

		XULog("Applying \(_changeSets.count) change sets.")
		
		let changeSets = _changeSets.sorted(by: { $0.timestamp < $1.timestamp })
		let errors = changeSets.map({ self._apply($0.changeSet) }).joined()
		if !errors.isEmpty {
			XULog("Some errors [\(errors.count)] occurred during synchronization: \(errors)")
		}
		
		for device in _devices {
			if let change = changeSets.reversed().first(where: { $0.deviceID == device.uuid }) {
				XUPreferences.shared.perform(andSynchronize: { (prefs) in
					prefs.setTimestampOfLastSynchronization(change.timestamp.timeIntervalSinceReferenceDate, with: device.uuid, ofDocumentWithIdentifier: self.documentManager.documentID)
				})
			}
		}
		
		try? self.documentManager.managedObjectContext.save()
		
		if !_changeSets.isEmpty {
			NotificationCenter.default.post(name: XUDocumentSyncManager.didApplySynchronizationChangesNotification, object: self.documentManager)
		}
		
		self._uploadPendingChanges()
	}
	
	/// Downloads changes from device at index in _devices.
	private func _downloadChangesFromDevice(at index: Int, cursor: CKQueryOperation.Cursor? = nil) {
		if index == _devices.count {
			DispatchQueue.main.sync {
				self._applyChanges()
			}
			return
		}
		
		_currentDeviceIndex = index
		
		let device = _devices[index]
		let operation: CKQueryOperation
		
		XULog("Synchronizing with device \(index)/\(_devices.count): \(device.uuid).")
		
		if let cursor = cursor {
			operation = CKQueryOperation(cursor: cursor)
		} else {
			let documentID = self.documentManager.documentID
			let prefs = XUPreferences.shared
			
			let lastChangeSetTimestamp = prefs.timestampOfLastSynchronization(with: device.uuid, ofDocumentWithIdentifier: documentID) ?? prefs.timestampOfImport(for: documentID)
			let lastChangeSetDate: Date
			if let timestamp = lastChangeSetTimestamp {
				lastChangeSetDate = Date(timeIntervalSinceReferenceDate: timestamp)
			} else {
				lastChangeSetDate = Date.distantPast
			}
			
			let predicate = NSPredicate(format: "deviceID == %@ AND documentID == %@ AND timestamp > %@", device.uuid, documentID, lastChangeSetDate as NSDate)
			let query = CKQuery(recordType: ChangeSet.recordType, predicate: predicate)
			
			operation = CKQueryOperation(query: query)
		}
		
		operation.resultsLimit = 100
		
		// Keeping cout of how many items got loaded so that we can track whether
		// everything was loaded.
		var fetchCount = 0
		
		operation.queryCompletionBlock = { (cursorOptional, error) in
			guard let cursor = cursorOptional else {
				if error == nil {
					XULog("Synchronization with device \(index)/\(self._devices.count): \(device.uuid) finished with no cursor, \(fetchCount) sync changes fetched.")
					self._downloadChangesFromDevice(at: index + 1)
					return // There is simply no cursor.
				}
				
				self.currentStep = .finished
				
				XULog("Synchronization with device \(index)/\(self._devices.count): \(device.uuid) failed with an error: \(error!).")
				
				let syncError = SynchronizationError(errorCode: .failedToDownloadChanges, underlyingError: error)
				self.completionHandler(syncError)
				return
			}
			
			XULog("Synchronization with device \(index)/\(self._devices.count): \(device.uuid) fetched \(fetchCount), cursor: \(cursor).")
			
			if fetchCount == operation.resultsLimit {
				self._downloadChangesFromDevice(at: index, cursor: cursor)
			} else {
				self._downloadChangesFromDevice(at: index + 1)
			}
		}
		operation.recordFetchedBlock = { (record) in
			fetchCount += 1
			
			if let change = ChangeSet(record: record) {
				self._changeSets.append(change)
				
				XULog("Synchronization with device \(index)/\(self._devices.count): \(device.uuid) fetched record \(fetchCount): \(change.timestamp).")
			} else {
				XULog("Synchronization with device \(index)/\(self._devices.count): \(device.uuid) failed to parse record \(record).")
			}
		}
		
		self.database.add(operation)
		
	}
	
	/// Synchronizes with devices listed in _devices. Asserts that currentStep is
	/// .listingDevices and that _devices is not empty.
	private func _synchronizeWithDevices() {
		assert(self.currentStep == .listingDevices)
		assert(!_devices.isEmpty)
		
		XULog("Synchronizing with \(_devices.count) devices.")
		
		self.currentStep = .downloadingChanges
		
		self._downloadChangesFromDevice(at: 0)
	}
	
	/// Takes changes from XUPreferences and uploads them.
	private func _uploadPendingChanges() {
		assert(self.currentStep == .applyingChanges)
		self.currentStep = .uploadingChanges
		
		XULog("Uploading changes for document ID \(self.documentManager.documentID).")
		
		self._uploadPendingChangesIfAny()
	}
	
	/// Keeps querying XUPreferences, if there are any changes to be removed.
	private func _uploadPendingChangesIfAny() {
		guard let pendingChange = XUPreferences.shared.pendingSynchronizationChanges(for: self.documentManager.documentID).first else {
			XULog("No pending changes for \(self.documentManager.documentID)")
			
			self.currentStep = .finished
			self.completionHandler(nil)
			return
		}
		
		let record = CKRecord(recordType: ChangeSet.recordType, recordID: CKRecord.ID(zoneID: self.documentManager.cloudKitContainerRecordZone.zoneID))
		record["documentID"] = self.documentManager.documentID as NSString
		record["timestamp"] = Date(timeIntervalSinceReferenceDate: pendingChange.changeSet.timestamp) as NSDate
		record["deviceID"] = XUSyncManagerPathUtilities.currentDeviceIdentifier as NSString
		
		// 1MB, but we make some reserve.
		if pendingChange.data.count > 900_000 {
			// Create CKAsset.
			let tempFileURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString + ".asset")
			do {
				try pendingChange.data.write(to: tempFileURL)
			} catch let err {
				XUFatalError("Failed to write pending change data to temporary file: \(tempFileURL) - \(err)")
			}
			
			let asset = CKAsset(fileURL: tempFileURL)
			record["asset"] = asset
		} else {
			record["payload"] = pendingChange.data as NSData
		}
		
		XULog("Uploading pending change \(pendingChange.changeSet.timestamp) for \(self.documentManager.documentID)")
		
		self.database.save(record) { (_, errorOptional) in
			if let error = errorOptional {
				XULog("Uploading pending change \(pendingChange.changeSet.timestamp) for \(self.documentManager.documentID) failed: \(error).")
				
				self.currentStep = .finished
				
				let syncError = SynchronizationError(errorCode: .failedToUploadChange, underlyingError: error)
				self.completionHandler(syncError)
				return
			}
			
			XULog("Uploaded pending change \(pendingChange.changeSet.timestamp) for \(self.documentManager.documentID)")
			
			let prefs = XUPreferences.shared
			prefs.perform(andSynchronize: { (prefs) in
				var dataList = prefs.pendingSynchronizationChanges(for: self.documentManager.documentID).map({ $0.data })
				if let index = dataList.index(of: pendingChange.data) {
					dataList.remove(at: index)
					prefs.setPendingSynchronizationChanges(dataList, for: self.documentManager.documentID)
				}
			})
			
			self._uploadPendingChangesIfAny()
		}
	}
	
	init(documentManager: XUDocumentSyncManager, completionHandler: @escaping CompletionHandler) {
		self.completionHandler = completionHandler
		self.database = documentManager.cloudKitContainer.privateCloudDatabase
		self.documentManager = documentManager
	}
	
	
	/// Starts synchronization. Asserts that currentStep is .initial.
	func startSynchronization() {
		assert(self.currentStep == .initial)
		self.currentStep = .listingDevices
		
		let listingQuery = CKQuery(recordType: SynchronizedDevice.recordType, predicate: NSPredicate(value: true))
		self.database.perform(listingQuery, inZoneWith: self.documentManager.cloudKitContainerRecordZone.zoneID) { (recordsOptional, error) in
			guard let records = recordsOptional, error == nil else {
				self.currentStep = .finished
				
				let syncError = SynchronizationError(errorCode: .failedToListDevices, underlyingError: error)
				self.completionHandler(syncError)
				return
			}
			
			// Map the records to SynchronizedDevice structs and filter out this
			// device as it makes no sense to sync against self.
			self._devices = records.compactMap(SynchronizedDevice.init(record:)).filter({ $0.uuid != XUSyncManagerPathUtilities.currentDeviceIdentifier })
			
			// If there are no participating devices, cancel the party.
			guard !self._devices.isEmpty else {
				self.currentStep = .finished
				self.completionHandler(nil)
				return
			}
			
			self._synchronizeWithDevices()
		}
	}
	
	
}
