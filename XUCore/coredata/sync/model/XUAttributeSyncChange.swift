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
	
	private struct CodingKeys {
		static let attributeName: String = "AttributeName"
		static let attributeValue: String = "AttributeValue"
	}
	
	/// Name of the attribute.
	public let attributeName: String
	
	/// Value of the attribute.
	public let attributeValue: Any?

	
	public override func encode(with coder: NSCoder) {
		coder.encode(self.attributeName, forKey: CodingKeys.attributeName)
		coder.encode(self.attributeValue, forKey: CodingKeys.attributeValue)
		
		super.encode(with: coder)
	}
	
	public init(object: XUManagedObject, attributeName name: String, value: Any?) {
		self.attributeName = name
		self.attributeValue = value
		
		super.init(object: object)
	}
	
	public required init?(coder decoder: NSCoder) {
		guard let name = decoder.decodeObject(forKey: CodingKeys.attributeName) as? String else {
			XULog("Can't find attribute name in decoder \(decoder)")
			return nil
		}
		
		self.attributeName = name
		self.attributeValue = decoder.decodeObject(forKey: CodingKeys.attributeValue)
		
		super.init(coder: decoder)
	}
		
}
