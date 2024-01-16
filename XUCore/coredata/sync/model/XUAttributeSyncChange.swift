//
//  XUAttributeSyncChange.swift
//  XUCore
//
//  Created by Charlie Monroe on 5/22/16.
//  Copyright © 2016 Charlie Monroe Software. All rights reserved.
//

import Foundation
import CoreData

@objc(XUAttributeSyncChangeValueTransformer)
final class XUAttributeSyncChangeValueTransformer: NSSecureUnarchiveFromDataTransformer {
	
	static let name = NSValueTransformerName("XUAttributeSyncChangeValueTransformer")
	
	override class func allowsReverseTransformation() -> Bool {
		return true
	}
	
	override class var allowedTopLevelClasses: [AnyClass] {
		return [
			NSNumber.self, NSString.self, NSDecimalNumber.self, NSDate.self, NSData.self
		]
	}
	
	class var allowedClasses: [(NSObject & NSCoding).Type] {
		return [
			NSNumber.self, NSString.self, NSDecimalNumber.self, NSDate.self, NSData.self
		]
	}
	
	override class func transformedValueClass() -> AnyClass {
		return NSData.self
	}
	
	public static func register() {
		let transformer = XUAttributeSyncChangeValueTransformer()
		ValueTransformer.setValueTransformer(transformer, forName: self.name)
	}
	
	override public func transformedValue(_ value: Any?) -> Any? {
		guard let value = value as? NSObject else {
			return nil
		}
		
		do {
			let data = try NSKeyedArchiver.archivedData(withRootObject: value, requiringSecureCoding: true)
			return data
		} catch {
			XUFatalError("Failed to transform `\(type(of: value))` to `Data`")
		}
	}
	
	override public func reverseTransformedValue(_ value: Any?) -> Any? {
		guard let data = value as? NSData else { return nil }
		
		for aClass in Self.allowedClasses {
			do {
				return try NSKeyedUnarchiver.unarchivedObject(ofClass: aClass, from: data as Data)
			} catch {
				continue
			}
		}
		
		XUFatalError("Failed to transform `Data` to any value: \((data as Data).hexEncodedString)")
	}
	
}


/// This class represents a change of attribute's value.
public final class XUAttributeSyncChange: XUSyncChange {
	
	private enum CodingKeys: String, CodingKey {
		case attributeName = "AttributeName"
		case attributeValue = "AttributeValue"
	}
	
	public override class var supportsSecureCoding: Bool {
		return true
	}
	
	
	/// Name of the attribute.
	public let attributeName: String
	
	/// Value of the attribute.
	public let attributeValue: Any?

	
	public override func encode(with coder: NSCoder) {
		coder.encode(self.attributeName, forKey: CodingKeys.attributeName.rawValue)
		coder.encode(self.attributeValue, forKey: CodingKeys.attributeValue.rawValue)
		
		super.encode(with: coder)
	}
	
	public override func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(attributeName, forKey: .attributeName)
		
		if let value = self.attributeValue {
			try container.encode(try PropertyListSerialization.data(fromPropertyList: value, format: .binary, options: 0), forKey: .attributeValue)
		}
	}
	
	public init(object: XUManagedObject, attributeName name: String, value: Any?) {
		self.attributeName = name
		self.attributeValue = value
		
		super.init(object: object)
	}
	
	public required init?(coder decoder: NSCoder) {
		guard let name = decoder.decodeObject(of: NSString.self, forKey: CodingKeys.attributeName.rawValue) as? String else {
			XULog("Can't find attribute name in decoder \(decoder)")
			return nil
		}
		
		self.attributeName = name
		self.attributeValue = decoder.decodeObject(forKey: CodingKeys.attributeValue.rawValue)
		
		super.init(coder: decoder)
	}
		
	public required init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
	
		self.attributeName = try container.decode(String.self, forKey: .attributeName)
		
		if let data = try container.decodeIfPresent(Data.self, forKey: .attributeValue) {
			self.attributeValue = try PropertyListSerialization.propertyList(from: data, format: nil)
		} else {
			self.attributeValue = nil
		}
		
		try super.init(from: decoder)
	}
	
}
