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
open class XUAttributeSyncChange: XUSyncChange {
	
	/// Name of the attribute.
	@NSManaged open fileprivate(set) var attributeName: String
	
	/// Value of the attribute.
	@NSManaged open fileprivate(set) var attributeValue: AnyObject?

	
	public init(object: XUManagedObject, attributeName name: String, andValue value: AnyObject?) {
		super.init(object: object)
		
		self.attributeName = name
		self.attributeValue = value
	}
	
	internal override init(entity: NSEntityDescription, insertInto context: NSManagedObjectContext?) {
		super.init(entity: entity, insertInto: context)
	}
	
}
