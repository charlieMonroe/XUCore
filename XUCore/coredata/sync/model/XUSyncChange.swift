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
public class XUSyncChange: NSObject, NSCoding, NSSecureCoding, Codable {
	
	private enum CodingKeys: String, CodingKey {
		case objectEntityName = "ObjectEntityName"
		case objectSyncID = "ObjectSyncID"
		case timestamp = "Timestamp"
	}
	
	public class var supportsSecureCoding: Bool {
		return true
	}

	
	/// Name of the entity.
	public let objectEntityName: String
	
	/// This is generally all we need to identify the object.
	public let objectSyncID: String
		
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
		coder.encode(self.objectEntityName, forKey: CodingKeys.objectEntityName.rawValue)
		coder.encode(self.objectSyncID, forKey: CodingKeys.objectSyncID.rawValue)
		coder.encode(self.timestamp, forKey: CodingKeys.timestamp.rawValue)
	}
	
	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(self.objectEntityName, forKey: .objectEntityName)
		try container.encode(self.objectSyncID, forKey: .objectSyncID)
		try container.encode(self.timestamp, forKey: .timestamp)
	}
	
	public required init?(coder decoder: NSCoder) {
		let timestamp = decoder.decodeDouble(forKey: CodingKeys.timestamp.rawValue)
		
		guard
			let entityName = decoder.decodeObject(of: NSString.self, forKey: CodingKeys.objectEntityName.rawValue) as? String,
			let objectID = decoder.decodeObject(of: NSString.self, forKey: CodingKeys.objectSyncID.rawValue) as? String,
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

	public required init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		self.objectEntityName = try container.decode(String.self, forKey: .objectEntityName)
		self.objectSyncID = try container.decode(String.self, forKey: .objectSyncID)
		self.timestamp = try container.decode(TimeInterval.self, forKey: .timestamp)
		
		super.init()
	}
	
}
