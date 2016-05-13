//
//  XUObjCProperty.swift
//  XUCore
//
//  Created by Charlie Monroe on 2/23/16.
//  Copyright © 2016 Charlie Monroe Software. All rights reserved.
//

import Foundation
import ObjectiveC

public func ==(property1: XUObjCProperty, property2: XUObjCProperty) -> Bool {
	return property1.propertyClass == property2.propertyClass && property1.name == property2.name
}

/// This class represents a property on an ObjC class (or a dynamic/@objc property
/// on a Swift class).
public class XUObjCProperty: CustomStringConvertible, Hashable {
	
	/// Returns a list of properties declared on a class, optionally including
	/// properties declared on superclasses.
	public class func propertiesOnClass(aClass: AnyClass, includingSuperclasses includeSuperclasses: Bool = false) -> [XUObjCProperty] {
		
		var properties: [XUObjCProperty] = []
		
		var cl: AnyClass! = aClass
		while cl != nil {
			var count: UInt32 = 0
			let props = class_copyPropertyList(cl, &count)
			for i in 0 ..< Int(count) {
				properties.append(XUObjCProperty(runtimeProperty: props[i], definedOnClass: cl))
			}
			
			free(props)
			
			if !includeSuperclasses {
				/// Do not include superclasses, break.
				break
			}
			
			cl = class_getSuperclass(cl)
		}
		
		return properties
	}
	
	
	/// Cached class for -propertyClass.
	private var _class: AnyClass?
	
	/// Returns a class name if !isScalar, otherwise nil. Note that nil is also
	/// returned for 'id'. For 'id<Protocol>', @"<Protocol>" is returned.
	public let className: String?
	
	/// The class the property is defined on. Note that this may be a subclass
	/// of the class passed into propertiesOnClass(_:).
	public let definedOnClass: AnyClass
	
	/// If true, the property is declared as readonly.
	public let isReadOnly: Bool
	
	/// Whether the property has a scalar value, i.e. is not an object.
	public let isScalar: Bool
	
	/// Name of the property.
	public let name: String

	
	public var description: String {
		return "\(self.isScalar ? "S" : "O") \(self.isReadOnly ? "RO" : "RW") \(self.name) (\(self.className ?? "--"))"
	}
	
	public var hashValue: Int {
		return "\(self.definedOnClass).\(self.name)".hash
	}
	
	/// Returns a property object for this particular property.
	public init(runtimeProperty: objc_property_t, definedOnClass aClass: AnyClass) {
		self.name = (NSString(UTF8String: property_getName(runtimeProperty)) as String?) ?? "<<unknown>>"
		self.definedOnClass = aClass
		
		let allPropertiesString = NSString(UTF8String: property_getAttributes(runtimeProperty)) as String? ?? ""
		let allProperties = allPropertiesString.componentsSeparatedByString(",")
		
		self.isReadOnly = allProperties.contains("R")
		
		/// ObjC type. If it's an object, starts with @, followed by ", class
		/// name and ", e.g. @"NSString"
		let typeProperty = allProperties.find({ $0.hasPrefix("T") })?.stringByDeletingPrefix("T") ?? ""
		self.isScalar = !typeProperty.hasPrefix("@")
		
		if !self.isScalar && typeProperty.characters.count > 3 {
			let typeString = typeProperty.stringByDeletingPrefix("@\"").stringByDeletingSuffix("\"")
			self.className = typeString
		} else {
			self.className = nil
		}
	}
	
	/// Class of the property, or Nil if the property is of a scalar value,
	/// or no particular class is defined (e.g. id, or id<MNAPIDataSource>).
	public var propertyClass: AnyClass? {
		if _class == nil && self.className != nil {
			_class = NSClassFromString(self.className!)
		}
		return _class
	}
	
}
