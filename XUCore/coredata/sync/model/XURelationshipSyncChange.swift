//
//  XURelationshipSyncChange.swift
//  XUCore
//
//  Created by Charlie Monroe on 5/22/16.
//  Copyright © 2016 Charlie Monroe Software. All rights reserved.
//

import Foundation
import CoreData

public class XURelationshipSyncChange: XUSyncChange {
	
	private enum CodingKeys: String, CodingKey {
		case relationshipName = "RelationshipName"
		case valueEntityName = "ValueEntityName"
		case valueSyncID = "ValueSyncID"
	}
	
	public override class var supportsSecureCoding: Bool {
		return true
	}
	
	/// Name of the relationship.
	public let relationshipName: String
	
	/// Name of the entity of value.
	public let valueEntityName: String?
	
	/// ID of the object that is being either deleted from or inserted into
	/// the relationship.
	public let valueSyncID: String?
	
	public override func encode(with coder: NSCoder) {
		super.encode(with: coder)
		
		coder.encode(self.relationshipName, forKey: CodingKeys.relationshipName.rawValue)
		coder.encode(self.valueEntityName, forKey: CodingKeys.valueEntityName.rawValue)
		coder.encode(self.valueSyncID, forKey: CodingKeys.valueSyncID.rawValue)
	}
	
	public override func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(self.relationshipName, forKey: .relationshipName)
		try container.encodeIfPresent(self.valueEntityName, forKey: .valueEntityName)
		try container.encodeIfPresent(self.valueSyncID, forKey: .valueSyncID)
	}

	public init(object: XUManagedObject, relationshipName relationship: String, andValue value: XUManagedObject?) {
		self.relationshipName = relationship
		self.valueEntityName = value?.entity.name
		self.valueSyncID = value?.syncUUID
		
		super.init(object: object)
	}
	
	public required init?(coder decoder: NSCoder) {
		guard let name = decoder.decodeObject(of: NSString.self, forKey: CodingKeys.relationshipName.rawValue) as? String else {
			let typeOfSelf = type(of: self)
			XULog("Failing to decode \(typeOfSelf) as it's missing some value from coder: \(decoder)")
			return nil
		}
		
		self.relationshipName = name
		self.valueEntityName = decoder.decodeObject(of: NSString.self, forKey: CodingKeys.valueEntityName.rawValue) as? String
		self.valueSyncID = decoder.decodeObject(of: NSString.self, forKey: CodingKeys.valueSyncID.rawValue) as? String
		
		super.init(coder: decoder)
	}
	
	public required init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		self.relationshipName = try container.decode(String.self, forKey: .relationshipName)
		self.valueEntityName = try container.decodeIfPresent(String.self, forKey: .relationshipName)
		self.valueSyncID = try container.decodeIfPresent(String.self, forKey: .relationshipName)
		
		try super.init(from: decoder)
	}
	
}

/// This class represents a change where an object was added into a -to-many
/// relationship set.
public final class XUToManyRelationshipAdditionSyncChange: XURelationshipSyncChange { 
	
	public override class var supportsSecureCoding: Bool {
		return true
	}
	
}

/// This class represents a change where an object was removed from a -to-many
/// relationship set.
public final class XUToManyRelationshipDeletionSyncChange: XURelationshipSyncChange { 
	
	public override class var supportsSecureCoding: Bool {
		return true
	}
	
}

public final class XUToOneRelationshipSyncChange: XURelationshipSyncChange { 
	
	public override class var supportsSecureCoding: Bool {
		return true
	}
	
}

