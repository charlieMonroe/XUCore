//
//  XUInsertionSyncChange.swift
//  XUCore
//
//  Created by Charlie Monroe on 5/22/16.
//  Copyright © 2016 Charlie Monroe Software. All rights reserved.
//

import Foundation
import CoreData

/// This class represents a sync change where an object has been inserted
/// into the MOC.
public final class XUInsertionSyncChange: XUSyncChange {
	
	/// A list of all attributes. Created by init(object:). Relationships are
	/// handled by separate relationship changes.
	public let attributes: [String : Any]
	
	/// Name of the entity being inserted. Created by -initWithObject:.
	public let insertedEntityName: String
	
	public override init(object: XUManagedObject) {
		super.init(object: object)
		
		// Create attribute changes
		let objectAttributeNames = object.entity.attributesByName
		var attributeValues: [String : Any] = [:]
		for (attributeName, _) in objectAttributeNames {
			attributeValues[attributeName] = object.value(forKey: attributeName) ?? NSNull()
		}
		
		self.attributes = attributeValues
		self.insertedEntityName = object.entity.name!
	}
	
}

/// This class represents a change where an object was added into a -to-many
/// relationship set.
public final class XUToManyRelationshipAdditionSyncChange: XURelationshipSyncChange { }

/// This class represents a change where an object was removed from a -to-many
/// relationship set.
public final class XUToManyRelationshipDeletionSyncChange: XURelationshipSyncChange { }

public final class XUToOneRelationshipSyncChange: XURelationshipSyncChange { }
