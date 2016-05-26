//
//  XURelationshipSyncChange.swift
//  XUCore
//
//  Created by Charlie Monroe on 5/22/16.
//  Copyright © 2016 Charlie Monroe Software. All rights reserved.
//

import Foundation

@objc(XURelationshipSyncChange)
public class XURelationshipSyncChange: XUSyncChange {
	
	/// Name of the relationship.
	@NSManaged public private(set) var relationshipName: String
	
	/// Name of the entity of value.
	@NSManaged public private(set) var valueEntityName: String?
	
	/// ID of the object that is being either deleted from or inserted into
	/// the relationship.
	@NSManaged public private(set) var valueSyncID: String?

	public init(object: XUManagedObject, relationshipName relationship: String, andValue value: XUManagedObject?) {
		super.init(object: object)
		
		self.relationshipName = relationship
		self.valueEntityName = value?.entity.name
		self.valueSyncID = value?.syncUUID
	}
	
	internal override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
		super.init(entity: entity, insertIntoManagedObjectContext: context)
	}

}
