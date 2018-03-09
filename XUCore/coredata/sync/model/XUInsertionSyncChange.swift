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
	
	private struct CodingKeys {
		static let attributes: String = "Attributes"
		static let insertedEntityName: String = "InsertedEntityName"
	}
	
	/// A list of all attributes. Created by init(object:). Relationships are
	/// handled by separate relationship changes.
	public let attributes: [String : Any]
	
	/// Name of the entity being inserted. Created by -initWithObject:.
	public let insertedEntityName: String
	
	
	public override func encode(with coder: NSCoder) {
		coder.encode(self.attributes, forKey: CodingKeys.attributes)
		coder.encode(self.insertedEntityName, forKey: CodingKeys.insertedEntityName)
		
		super.encode(with: coder)
	}
	
	public override init(object: XUManagedObject) {
		// Create attribute changes
		let objectAttributeNames = object.entity.attributesByName
		var attributeValues: [String : Any] = [:]
		for (attributeName, _) in objectAttributeNames {
			attributeValues[attributeName] = object.value(forKey: attributeName) ?? NSNull()
		}
		
		self.attributes = attributeValues
		self.insertedEntityName = object.entity.name!
		
		super.init(object: object)
	}
	
	public required init?(coder decoder: NSCoder) {
		guard
			let entityName = decoder.decodeObject(forKey: CodingKeys.insertedEntityName) as? String,
			let values = decoder.decodeObject(forKey: CodingKeys.attributes) as? [String : Any]
		else {
			XULog("Failing to decode XUInsertionSyncChange as it's missing some value from coder: \(decoder)")
			return nil
		}
		
		self.attributes = values
		self.insertedEntityName = entityName
		
		super.init(coder: decoder)
	}
	
}
