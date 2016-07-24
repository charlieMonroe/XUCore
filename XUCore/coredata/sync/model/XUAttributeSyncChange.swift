//
//  XUAttributeSyncChange.swift
//  XUCore
//
//  Created by Charlie Monroe on 5/22/16.
//  Copyright © 2016 Charlie Monroe Software. All rights reserved.
//

import Foundation
import CoreData

/// This class represents a change of attribute's value.
@objc(XUAttributeSyncChange)
public class XUAttributeSyncChange: XUSyncChange {
	
	/// Name of the attribute.
	@NSManaged public private(set) var attributeName: String
	
	/// Value of the attribute.
	@NSManaged public private(set) var attributeValue: AnyObject?

	
	public init(object: XUManagedObject, attributeName name: String, andValue value: AnyObject?) {
		super.init(object: object)
		
		self.attributeName = name
		self.attributeValue = value
	}
	
	internal override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
		super.init(entity: entity, insertIntoManagedObjectContext: context)
	}
	
}