//
//  XUCloudKitDeviceRegistry.swift
//  XUCore
//
//  Created by Charlie Monroe on 3/9/18.
//  Copyright © 2018 Charlie Monroe Software. All rights reserved.
//

import CloudKit
import Foundation

/// Class that registers the device in iCloud as Synchronized Device. It also keeps
/// the subscription.
@available(iOSApplicationExtension, unavailable)
internal class XUCloudKitDeviceRegistry {
	
	/// A subscription ID. Each document has its own subscription which is encoded
	/// in the ID. This structure allows encoding it forth and back.
	struct SubscriptionID: RawRepresentable {
		
		/// Device ID.
		let deviceID: String
		
		/// Document ID.
		let documentID: String
		
		/// Raw value of the subscription ID.
		let rawValue: String
		
		init?(rawValue: String) {
			let regex = "XU_SYNC_SUBSCRIPTION_(?P<DOC>.*)_DEVICE_(?P<DEVICE>.*)"
			guard let documentID = rawValue.value(of: "DOC", inRegex: regex), let deviceID = rawValue.value(of: "DEVICE", inRegex: regex) else {
				XULog("Can't decode subscription ID with raw value \(rawValue).")
				return nil
			}
			
			self.rawValue = rawValue
			self.deviceID = deviceID
			self.documentID = documentID
		}
		
		/// Initialize from documentID and deviceID.
		init(documentID: String, deviceID: String = XUSyncManagerPathUtilities.currentDeviceIdentifier) {
			self.rawValue = "XU_SYNC_SUBSCRIPTION_\(documentID)_DEVICE_\(deviceID)"
			self.deviceID = deviceID
			self.documentID = documentID
		}
		
	}
	
	
	/// Database.
	let database: CKDatabase
	
	/// Document ID.
	let documentID: String
	
	/// Marked as true when we find the device in iCloud.
	private(set) var isRegistered: Bool = false {
		didSet {
			if self.isRegistered {
				self._checkSubscription()
			}
		}
	}
	
	/// Zone.
	let recordZone: CKRecordZone
	
	/// Subscription ID.
	let subscriptionID: String
	
	init(database: CKDatabase, recordZone: CKRecordZone, documentID: String) {
		self.database = database
		self.documentID = documentID
		self.recordZone = recordZone
		self.subscriptionID = SubscriptionID(documentID: documentID).rawValue
		
		self.register()
	}
	
	private func _checkDeviceExistence() {
		let query = CKQuery(recordType: XUCloudKitSynchronization.SynchronizedDevice.recordType, predicate: NSPredicate(format: "uuid == %@", XUSyncManagerPathUtilities.currentDeviceIdentifier))
		self.database.perform(query, inZoneWith: self.recordZone.zoneID) { (records, error) in
			if let error = error {
				XULog("Failed to fetch current device from CloudKit: \(error).")
			} else {
				XULog("Found device records: \(records.descriptionWithDefaultValue())")
				
				self.isRegistered = !records.isNilOrEmpty
				
				if !self.isRegistered {
					self._registerDevice()
				}
			}
		}
	}
	
	private func _checkSubscription() {
		XULog("Checking subscription.")
		
		self.database.fetch(withSubscriptionID: self.subscriptionID) { (subscriptionOptional, errorOptional) in
			if let subscription = subscriptionOptional {
				XULog("Already subscribed to: \(subscription)")
			} else if let error = errorOptional, (error as NSError).code != CKError.unknownItem.rawValue {
				XULog("Could not list subscription: \(error)")
			} else {
				XULog("Not subscribed, subscribing.")
				self._subscribeToChanges()
			}
		}
	}
	
	/// Actually registers self.
	private func _registerDevice() {
		let record = CKRecord(recordType: XUCloudKitSynchronization.SynchronizedDevice.recordType, recordID: CKRecord.ID(zoneID: self.recordZone.zoneID))
		#if os(macOS)
			record["name"] = (Host.current().localizedName ?? "unknown") as NSString
		#else
			record["name"] = UIDevice.current.name as NSString
		#endif
		record["uuid"] = XUSyncManagerPathUtilities.currentDeviceIdentifier as NSString
		
		self.database.save(record) { (record, error) in
			if let error = error {
				XULog("Failed to register current device with CloudKit: \(error).")
			} else if let record = record {
				XULog("Register current device with CloudKit: \(record).")
				self.isRegistered = true
			} else {
				XULog("Both record and error are nil... ¯\\_(ツ)_/¯")
			}
		}
	}
	
	private func _registerZone() {
		let zoneOperation = CKModifyRecordZonesOperation(recordZonesToSave: [self.recordZone], recordZoneIDsToDelete: nil)
		zoneOperation.modifyRecordZonesCompletionBlock = { (zonesAdded, _, errorOptional) in
			if let error = errorOptional {
				XULog("Failed to create zone in CloudKit: \(error).")
			} else {
				XULog("Created zones: \(zonesAdded.descriptionWithDefaultValue())")
				self._registerDevice()
			}
		}
		
		self.database.add(zoneOperation)
	}
	
	private func _subscribeToChanges() {
		let predicate = NSPredicate(format: "documentID = %@ AND deviceID != %@", self.documentID, XUSyncManagerPathUtilities.currentDeviceIdentifier)
		
		let subscription: CKSubscription
		if #available(macOS 10.12, iOS 10.0, *) {
			subscription = CKQuerySubscription(recordType: XUCloudKitSynchronization.ChangeSet.recordType, predicate: predicate, subscriptionID: self.subscriptionID, options: .firesOnRecordCreation)
		} else {
			XULog("Change subscription currently not available on macOS 11.")
			return
//			subscription = CKSubscription(recordType: XUCloudKitSynchronization.ChangeSet.recordType, predicate: predicate, subscriptionID: self.subscriptionID, options: .firesOnRecordCreation)
		}
		
		let info = CKSubscription.NotificationInfo()
		subscription.notificationInfo = info
		
		self.database.save(subscription) { (subscriptionOptional, errorOptional) in
			if let subscription = subscriptionOptional {
				XULog("Successfully subscribed: \(subscription)")
			} else {
				XULog("Could not subscribe: \(errorOptional.descriptionWithDefaultValue())")
			}
		}
	}
	
	/// Registers self in the CloudKit if necessary.
	func register() {
		guard !self.isRegistered else {
			return
		}
		
		self.database.fetch(withRecordZoneID: self.recordZone.zoneID, completionHandler: { (zone, errorOptional) in
			if let error = errorOptional, (error as NSError).code != CKError.zoneNotFound.rawValue {
				XULog("Failed to fetch zones from CloudKit: \(error).")
			} else {
				XULog("Found zone: \(zone.descriptionWithDefaultValue())")
				
				if zone != nil {
					self._checkDeviceExistence()
				} else {
					self._registerZone()
				}
			}
		})
	}
	
}
