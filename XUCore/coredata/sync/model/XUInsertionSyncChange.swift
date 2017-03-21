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
@objc(XUInsertionSyncChange)
public final class XUInsertionSyncChange: XUSyncChange {
	
	/// A list of all attributes. Created by -initWithObject:. Relationships are
	/// handled by separate relationship changes.
	///
	/// The dictionary is marked as Transformable, hence it's not all that efficient
	/// when it comes to deserialization - if possible, query this property as little
	/// as possible.
	@NSManaged public private(set) var attributes: [String : AnyObject]
	
	/// Name of the entity being inserted. Created by -initWithObject:.
	@NSManaged public private(set) var insertedEntityName: String
	
	public override init(object: XUManagedObject) {
		super.init(object: object)
		
		// Create attribute changes
		let objectAttributeNames = object.entity.attributesByName
		var attributeValues: [String : AnyObject] = [:]
		for (attributeName, _) in objectAttributeNames {
			attributeValues[attributeName] = object.value(forKey: attributeName) as AnyObject?
		}
		
		self.attributes = attributeValues
		self.insertedEntityName = object.entity.name!
	}
	
	internal override init(entity: NSEntityDescription, insertInto context: NSManagedObjectContext?) {
		super.init(entity: entity, insertInto: context)
	}
	
}

/// This class represents a change where an object was added into a -to-many
/// relationship set.
@objc(XUToManyRelationshipAdditionSyncChange)
public final class XUToManyRelationshipAdditionSyncChange: XURelationshipSyncChange { }

/// This class represents a change where an object was removed from a -to-many
/// relationship set.
@objc(XUToManyRelationshipDeletionSyncChange)
public final class XUToManyRelationshipDeletionSyncChange: XURelationshipSyncChange { }

@objc(XUToOneRelationshipSyncChange)
public final class XUToOneRelationshipSyncChange: XURelationshipSyncChange { }
