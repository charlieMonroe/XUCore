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
public final class XUAttributeSyncChange: XUSyncChange {
	
	/// Name of the attribute.
	public let attributeName: String
	
	/// Value of the attribute.
	public let attributeValue: Any?

	
	public init(object: XUManagedObject, attributeName name: String, value: Any?) {
		self.attributeName = name
		self.attributeValue = value
		
		super.init(object: object)
	}
		
}
