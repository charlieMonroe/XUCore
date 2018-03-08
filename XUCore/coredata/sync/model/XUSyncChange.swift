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
public class XUSyncChange: Codable {
	
	private enum CodingKeys: String, CodingKey {
		case objectEntityName
		case objectSyncID
		case timestamp
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
	public let syncObject: XUManagedObject?
	
	/// Timestamp of the change.
	public let timestamp: TimeInterval
	
	
	/// Creates a new sync change.
	public init(object: XUManagedObject) {
		self.syncObject = object
		
		self.objectEntityName = object.entity.name!
		self.objectSyncID = object.syncUUID
		self.timestamp = Date.timeIntervalSinceReferenceDate
	}
	
	
	
	public required init(from decoder: Decoder) throws {
		let values = try decoder.container(keyedBy: CodingKeys.self)
		
		self.syncObject = nil
		
		self.objectEntityName = try values.decode(String.self, forKey: .objectEntityName)
		self.objectSyncID = try values.decode(String.self, forKey: .objectSyncID)
		self.timestamp = try values.decode(TimeInterval.self, forKey: .timestamp)
	}

}
