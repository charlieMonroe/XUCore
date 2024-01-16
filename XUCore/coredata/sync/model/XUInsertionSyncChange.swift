//
//  XUInsertionSyncChange.swift
//  XUCore
//
//  Created by Charlie Monroe on 5/22/16.
//  Copyright © 2016 Charlie Monroe Software. All rights reserved.
//

import Foundation
import CoreData

@objc(XUInsertionSyncChangeAtributesTransformer)
final class XUInsertionSyncChangeAtributesTransformer: NSSecureUnarchiveFromDataTransformer {
	
	static let name = NSValueTransformerName("XUInsertionSyncChangeAtributesTransformer")
	
	override class func allowsReverseTransformation() -> Bool {
		return true
	}
	
	override class var allowedTopLevelClasses: [AnyClass] {
		return [NSDictionary.self]
	}
	
	override class func transformedValueClass() -> AnyClass {
		return NSData.self
	}
	
	public static func register() {
		let transformer = XUInsertionSyncChangeAtributesTransformer()
		ValueTransformer.setValueTransformer(transformer, forName: self.name)
	}
	
	override public func transformedValue(_ value: Any?) -> Any? {
		guard let dict = value as? NSDictionary else { return nil }
		
		do {
			let data = try NSKeyedArchiver.archivedData(withRootObject: dict, requiringSecureCoding: true)
			return data
		} catch {
			XUFatalError("Failed to transform `NSDictionary` to `Data`")
		}
	}
	
	override public func reverseTransformedValue(_ value: Any?) -> Any? {
		guard let data = value as? NSData else { return nil }
		
		do {
			let dict = try NSKeyedUnarchiver.unarchivedObject(ofClass: NSDictionary.self, from: data as Data)
			return dict
		} catch {
			XULog("Failed to transform `Data` to `NSDictionary`")
			return nil
		}
	}
	
}

/// This class represents a sync change where an object has been inserted
/// into the MOC.
public final class XUInsertionSyncChange: XUSyncChange {
	
	fileprivate enum CodingKeys: String, CodingKey {
		case attributes = "Attributes"
		case insertedEntityName = "InsertedEntityName"
	}
	
	public override class var supportsSecureCoding: Bool {
		return true
	}
	
	/// A list of all attributes. Created by init(object:). Relationships are
	/// handled by separate relationship changes.
	public let attributes: [String : Any]
	
	/// Name of the entity being inserted. Created by -initWithObject:.
	public let insertedEntityName: String
	
	
	public override func encode(with coder: NSCoder) {
		coder.encode(self.attributes, forKey: CodingKeys.attributes.rawValue)
		coder.encode(self.insertedEntityName, forKey: CodingKeys.insertedEntityName.rawValue)
		
		super.encode(with: coder)
	}
	
	public override func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(self.insertedEntityName, forKey: .insertedEntityName)
		try container.encode(try PropertyListSerialization.data(fromPropertyList: attributes, format: .binary, options: 0), forKey: .attributes)
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
			let entityName = decoder.decodeObject(of: NSString.self, forKey: CodingKeys.insertedEntityName.rawValue) as? String,
			let values = decoder.decodeAttributes() as? [String : Any]
		else {
			XULog("Failing to decode XUInsertionSyncChange as it's missing some value from coder: \(decoder)")
			return nil
		}
		
		self.attributes = values
		self.insertedEntityName = entityName
		
		super.init(coder: decoder)
	}
	
	public required init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		self.insertedEntityName = try container.decode(String.self, forKey: .insertedEntityName)
		
		let valuesObject = try PropertyListSerialization.propertyList(from: container.decode(Data.self, forKey: .attributes), format: nil)
		guard let dict = valuesObject as? [String : Any] else {
			throw DecodingError.typeMismatch(type(of: valuesObject), .init(codingPath: [CodingKeys.attributes], debugDescription: "Cannot cast to dictionary."))
		}
		
		self.attributes = dict
		
		try super.init(from: decoder)
	}
	
}

//private extension NSCoder {
//	
//	func decodeAttributes() -> [String : Any]? {
//		if let attributes = self.decodeObject(forKey: XUInsertionSyncChange.CodingKeys.attributes.rawValue) as? [String : Any] {
//			return attributes
//		}
//		
//		if #available(macOS 11.0, *) {
//			return self.decodeDictionary(withKeysOfClasses: [NSString.self], objectsOfClasses: XUAttributeSyncChangeValueTransformer.allowedClasses, forKey: XUInsertionSyncChange.CodingKeys.attributes.rawValue) as? [String : Any]
//		} else {
//			return self.decodeObject(of: [NSDictionary.self] + XUAttributeSyncChangeValueTransformer.allowedClasses, forKey: XUInsertionSyncChange.CodingKeys.attributes.rawValue) as? [String : Any]
//		}
//		
//	}
//	
//}
