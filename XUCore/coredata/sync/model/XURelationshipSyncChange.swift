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
	
	/// Name of the relationship.
	public let relationshipName: String
	
	/// Name of the entity of value.
	public let valueEntityName: String?
	
	/// ID of the object that is being either deleted from or inserted into
	/// the relationship.
	public let valueSyncID: String?

	public init(object: XUManagedObject, relationshipName relationship: String, andValue value: XUManagedObject?) {
		self.relationshipName = relationship
		self.valueEntityName = value?.entity.name
		self.valueSyncID = value?.syncUUID
		
		super.init(object: object)
	}
	
}
