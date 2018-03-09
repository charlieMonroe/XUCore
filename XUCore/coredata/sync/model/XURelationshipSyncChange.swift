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
	
	private struct CodingKeys {
		static let relationshipName: String = "RelationshipName"
		static let valueEntityName: String = "ValueEntityName"
		static let valueSyncID: String = "ValueSyncID"
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
		
		coder.encode(self.relationshipName, forKey: CodingKeys.relationshipName)
		coder.encode(self.valueEntityName, forKey: CodingKeys.valueEntityName)
		coder.encode(self.valueSyncID, forKey: CodingKeys.valueSyncID)
	}

	public init(object: XUManagedObject, relationshipName relationship: String, andValue value: XUManagedObject?) {
		self.relationshipName = relationship
		self.valueEntityName = value?.entity.name
		self.valueSyncID = value?.syncUUID
		
		super.init(object: object)
	}
	
	public required init?(coder decoder: NSCoder) {
		guard let name = decoder.decodeObject(forKey: CodingKeys.relationshipName) as? String else {
			let typeOfSelf = type(of: self)
			XULog("Failing to decode \(typeOfSelf) as it's missing some value from coder: \(decoder)")
			return nil
		}
		
		self.relationshipName = name
		self.valueEntityName = decoder.decodeObject(forKey: CodingKeys.valueEntityName) as? String
		self.valueSyncID = decoder.decodeObject(forKey: CodingKeys.valueSyncID) as? String
		
		super.init(coder: decoder)
	}
	
}

/// This class represents a change where an object was added into a -to-many
/// relationship set.
public final class XUToManyRelationshipAdditionSyncChange: XURelationshipSyncChange { }

/// This class represents a change where an object was removed from a -to-many
/// relationship set.
public final class XUToManyRelationshipDeletionSyncChange: XURelationshipSyncChange { }

public final class XUToOneRelationshipSyncChange: XURelationshipSyncChange { }

