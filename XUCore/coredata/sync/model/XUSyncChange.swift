//
//  XUSyncChange.swift
//  XUCore
//
//  Created by Charlie Monroe on 5/21/16.
//  Copyright © 2016 Charlie Monroe Software. All rights reserved.
//

import Foundation
import CoreData


/// This is a base class for all sync changes.
public class XUSyncChange: NSObject, NSCoding {
	
	private struct CodingKeys {
		static let objectEntityName: String = "ObjectEntityName"
		static let objectSyncID: String = "ObjectSyncID"
		static let timestamp: String = "Timestamp"
	}

	
	/// Change set this change belongs to. Nil during initialization, hence nullable,
	/// but otherwise should be nonnull.
	@available(*, deprecated)
	public private(set) var changeSet: XUSyncChangeSet!
	
	/// Name of the entity.
	public let objectEntityName: String
	
	/// This is generally all we need to identify the object.
	public let objectSyncID: String
	
	/// Object that is being sync'ed. This is only referenced when freshly created
	/// from that object.
	@available(*, deprecated)
	public let syncObject: XUManagedObject? = nil
	
	/// Timestamp of the change.
	public let timestamp: TimeInterval
	
	
	/// Creates a new sync change.
	public init(object: XUManagedObject) {
		self.objectEntityName = object.entity.name!
		self.objectSyncID = object.syncUUID
		self.timestamp = Date.timeIntervalSinceReferenceDate
		
		super.init()
	}
	
	
	public func encode(with coder: NSCoder) {
		coder.encode(self.objectEntityName, forKey: CodingKeys.objectEntityName)
		coder.encode(self.objectSyncID, forKey: CodingKeys.objectSyncID)
		coder.encode(self.timestamp, forKey: CodingKeys.timestamp)
	}
	
	public required init?(coder decoder: NSCoder) {
		let timestamp = decoder.decodeDouble(forKey: CodingKeys.timestamp)
		
		guard
			let entityName = decoder.decodeObject(forKey: CodingKeys.objectEntityName) as? String,
			let objectID = decoder.decodeObject(forKey: CodingKeys.objectSyncID) as? String,
			timestamp != 0.0
		else {
			XULog("Sync Change cannot be decoded - missing value: \(decoder)")
			return nil
		}
		
		self.objectEntityName = entityName
		self.objectSyncID = objectID
		self.timestamp = timestamp
		
		super.init()
	}

}
