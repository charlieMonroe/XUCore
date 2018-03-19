//
//  XUCloudKitSynchronization+SupportingStructures.swift
//  XUCore
//
//  Created by Charlie Monroe on 3/9/18.
//  Copyright © 2018 Charlie Monroe Software. All rights reserved.
//

import CloudKit
import Foundation

extension XUCloudKitSynchronization {
	
	/// Structure defining the change set.
	struct ChangeSet {
		
		/// Payload of the change set.
		enum Payload {
			case asset(CKAsset)
			case data(Data)
		}
		
		/// Record type holding the change set.
		static let recordType: String = "XUChangeSet"
		
		
		/// Change set deserialized from the payload.
		let changeSet: XUSyncChangeSet
		
		/// Device UUID.
		let deviceID: String
		
		/// Payload - either direct data or an asset (1+MB).
		let payload: Payload
		
		/// Timestamp of the change set.
		let timestamp: Date
		
		/// Creates a synchronized device structure. Will return nil if required
		/// value is missing.
		init?(record: CKRecord) {
			guard
				let timestamp = record["timestamp"] as? Date, let payloadAny = record["payload"] ?? record["asset"],
				let deviceID = record["deviceID"] as? String
			else {
				XULog("Failed to create a change set from \(record).")
				return nil
			}

			self.deviceID = deviceID
			self.timestamp = timestamp
			
			if let data = payloadAny as? Data {
				self.payload = .data(data)
			} else if let asset = payloadAny as? CKAsset {
				self.payload = .asset(asset)
			} else {
				XUFatalError("Received payload that is neither Data nor CKAsset: \(type(of: payloadAny)) \(record)")
			}
			
			let data: Data
			switch self.payload {
			case .data(let d):
				data = d
			case .asset(let asset):
				do {
					data = try Data(contentsOf: asset.fileURL)
				} catch let error {
					XULog("Failed to read data of asset \(asset) when creating synch change from record: \(record) - \(error)")
					return nil
				}
			}
			
			guard let object = NSKeyedUnarchiver.unarchiveObject(with: data) else {
				XULog("Failed to deserialize sync change from data \(data.hexEncodedString): \(record)")
				return nil
			}
			
			guard let changeSet = object as? XUSyncChangeSet else {
				XULog("Deserialized data is not an XUSyncChangeSet: \(type(of: object)) - \(object)")
				return nil
			}
			
			self.changeSet = changeSet
		}
		
	}

	
	/// Structure defining the synchronized device.
	struct SynchronizedDevice {
		
		/// Record type holding the synchronized device. This device participates
		/// in the synchronization process
		static let recordType: String = "XUSynchronizedDevice"
		
		/// Name of the device.
		let name: String
		
		/// UUID of the device.
		let uuid: String
		
		/// Creates a synchronized device structure. Will return nil if required
		/// value is missing.
		init?(record: CKRecord) {
			guard let name = record["name"] as? String, let uuid = record["uuid"] as? String else {
				XULog("Failed to create a synchronized device from \(record).")
				return nil
			}
			
			self.name = name
			self.uuid = uuid
		}
		
	}

}
