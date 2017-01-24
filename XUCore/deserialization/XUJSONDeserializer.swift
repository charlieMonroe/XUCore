//
//  XUJSONDeserializer.swift
//  XUCore
//
//  Created by Charlie Monroe on 2/23/16.
//  Copyright © 2016 Charlie Monroe Software. All rights reserved.
//

import CoreData
import Foundation

/// We're caching the properties, since they are likely to be often reused. The 
/// cache is two-level. First, it is ObjectIdentifier(class) -> class-specific
/// cache. The class-specific cache contains up to three entries for each property:
///		- regular name -> XUObjCProperty mapping for properties that actually match.
///		- lowercase name -> XUObjCProperty for a quicker lookup
///		- match -> XUObjCProperty for future mappings.
private var _cachedProperties: [ObjectIdentifier : [String : XUObjCProperty]] = [:]
private var _cacheLock: NSLock = NSLock(name: "com.charliemonroe.XUJSONDeserialization.XUObjCPropertyCache")


/// Reserved read-only properties used by Foundation/NSObject/CoreData.
private let reservedProperties = [
	"accessibilityActivationPoint", "accessibilityCustomActions", "accessibilityElements",
	"accessibilityElementsHidden", "accessibilityFrame", "accessibilityHint",
	"accessibilityLabel", "accessibilityLanguage", "accessibilityNavigationStyle",
	"accessibilityPath", "accessibilityTraits", "accessibilityValue", "accessibilityViewIsModal",
	"autoContentAccessingProxy", "classForKeyedArchiver", "debugDescription", "description",
	"hash", "isAccessibilityElement", "observationInfo", "shouldGroupAccessibilityChildren",
	"superclass", "traitStorageList"
]

public enum XUJSONDeserializationError {

	/// Returned if there are no issues when deserializing the object.
	case none

	/// The deserialization was successful with minor warnings, for example, the
	/// dictionary contained a key that was not handled by the deserializer, nor
	/// the XUJSONDeserializable object (i.e. it can't find a property, yet
	/// ignoreKey(_:) returns false.
	case warning

	/// A fatal error has occurred when deserializing the object. This can for
	/// example be if the setValue(_:forKey:) method throws an exception because
	/// you are setting e.g. a NSNumber into a NSString property.
	case error

	public func isMoreSevere(than otherError: XUJSONDeserializationError) -> Bool {
		if otherError == self {
			return false
		}

		if self == .none {
			return false
		}

		if self == .warning {
			return otherError != .error
		}

		return true
	}
}

/// Used as a return value for per-key results.
private enum XUJSONDeserializationPropertyResult {
	
	case deserializedValue(property: XUObjCProperty, value: Any?, error: XUJSONDeserializationError)
	case customDeserializationPerformed // Custom deserialization performed.
	case ignored // Ignored by object returning true from .ignoreKey(_:)
	case unhandled(error: XUJSONDeserializationError) // Not handled at all.
	case error // Error.
	
}

/// All classes that want to be deserialized by the deserializer must conform to
/// this protocol. @objc is required for CoreData.
@objc public protocol XUJSONDeserializable: AnyObject {
	
	/// This is implemented by NSObject. If you are not basing your class on 
	/// NSObject, you need to do this yourself.
	func setValue(_ value: Any?, forKey: String)

	/// This method is called when the deserializer encounters a dictionary under
	/// `key`. The returned object doesn't necessarily need to conform to
	/// XUJSONDeserializable - it can be e.g. NSString.
	///
	/// @note - If the returned object is not conforming to XUJSONDeserializable,
	/// the deserializer stops there, otherwise it keeps deserializing
	/// the dictionary into the returned object.
	///
	/// - the deserializer calls this method even if an array of objects is
	/// stored under this key. In such case, this method is called n-times,
	/// where n is the number of items in the array.
	///
	/// - if nil is returned, the object is given another chance in
	/// performCustomDeserialization* methods.
	@objc optional func createObjectForKey(_ key: String) -> AnyObject?

	/// Dates are tricky to deserialize since JSON doesn't specify a format for
	/// them. The default implementation assumes ISO8601 format and tries to
	/// deserialize it. You can customize this behavior.
	@objc optional func dateFromString(_ dateString: String, forKey key: String) -> Date?
	
	/// The serializer supports updating already existing entities from fetched
	/// content. When the serializer encounters a dictionary, it asks for the
	/// entityID. If a non-nil object is returned, fetchEntityWithID(_:forKey:)
	/// is invoked.
	///
	/// @note - the `key` parameter refers to the the key currently being deserialized.
	@objc optional func entityIDInDictionary(_ dictionary: XUJSONDictionary, forKey key: String) -> Any?

	/// entityIDInDictionary(_:forKey:) returned a non-nil value which is passed
	/// as `entityID` parameter here. You should return the entity with this ID.
	///
	/// @note - the `key` parameter refers to the the key currently being deserialized.
	@objc optional func fetchEntityWithID(_ entityID: Any, forKey key: String) -> AnyObject?
	
	/// Return true if you want to ignore this key. If true is returned, the
	/// deserializer will not call any further methods.
	@objc optional func ignoreKey(_ key: String) -> Bool
	
	/// You can observe the fact that you were deserialized by implementing this
	/// method.
	@objc optional func objectWasDeserializedFromDictionary(_ dictionary: XUJSONDictionary)

	/// When the deserializer encounters an array of strings or numbers (NSNumber),
	/// it will call this method assuming that those are IDs or some other objects.
	/// The default implementation returns nil.
	@objc optional func mapIDs(_ IDs: [Any], toObjectsForKey key: String) -> [AnyObject]?

	/// When the createObjectForKey(_:) method returns nil, the deserializer
	/// calls this method. Return true to indicate that the custom deserialization
	/// was successful, false that it was not.
	@objc optional func performCustomDeserializationOfObject(_ object: XUJSONDictionary, forKey key: String) -> Bool

	/// When the createObjectForKey(_:) method returns nil, the deserializer
	/// calls this method. Return true to indicate that the custom deserialization
	/// was successful, false that it was not.
	@objc optional func performCustomDeserializationOfObjects(_ objects: [Any], forKey key: String) -> Bool

	/// Returns the name of the property for that particular key. By default,
	/// if nil is returned, the deserializer goes through the class' properties
	/// and finds one that is a case-insensitive match.
	@objc optional func propertyNameForDictionaryRepresentationKey(_ key: String) -> String?

	/// Transforms the value to the representation required by the class. Return
	/// nil if you don't want transformation for that key to occurr.
	@objc optional func transformedValue(_ value: Any?, forKey key: String) -> Any?
}


/// This class is to be used for a semi-automatic JSON deserialization. It is
/// fairly flexible and the deserialization process can be fairly well customized.
///
/// The object to be deserialized must conform to the XUJSONDeserializable
/// protocol - which is by default implemented in the protocol extension, so
/// you really don't need to implement anything.
///
/// Note that the deserialization will work only on properties that are declared
/// as dynamic or @objc from the nature of the deserialization.
public final class XUJSONDeserializer {

	fileprivate static let XUJSONDeserializerThreadKey = "XUJSONDeserializerThreadKey"

	/// Returns the default deserializer. Each thread has its own instance that
	/// is lazily created.
	public class var defaultDeserializer: XUJSONDeserializer {
		let threadDictionary = Thread.current.threadDictionary
		if let deserializer = threadDictionary[XUJSONDeserializerThreadKey] as? XUJSONDeserializer {
			return deserializer
		}

		let deserializer = XUJSONDeserializer()
		threadDictionary[XUJSONDeserializerThreadKey] = deserializer
		return deserializer
	}

	/// If you set this static var to true, the deserializer will maintain the
	/// deserializationLog. Note that this is for debugging purposes only and
	/// should in no way be turned on in production environment, since it degrades
	/// performance greatly as well as keeps references to the deserialized objects.
	public static var deserializationLoggingEnabled: Bool = XUAppSetup.isRunningInDebugMode

	/// Exception catcher.
	fileprivate let _exceptionHandler = XUExceptionCatcher()

	/// Deserialization log. This will contain all the warnings and errors. Only
	/// populated if deserializationLoggingEnabled is true. Remember that the
	/// deserializer is provided on per-thread basis, so each time the thread dies,
	/// the log dies with it.
	public fileprivate(set) var deserializationLog: [XUJSONDeserializationLogEntry] = []

	/// You can set logging enabled per deserializer. By default contains the
	/// global option.
	public var isLoggingEnabled: Bool = XUJSONDeserializer.deserializationLoggingEnabled

	fileprivate func _addLogEntry(_ severity: XUJSONDeserializationError, objectClass: AnyClass, key: String, additionalInformation: String = "") {
		if !self.isLoggingEnabled {
			return
		}
		
		let entry = XUJSONDeserializationLogEntry(severity: severity, objectClass: objectClass, key: key, additionalInformation: additionalInformation)
		self.deserializationLog.append(entry)
		XULog(entry.debugDescription)
	}
	
	private func _canAssign(_ value: Any, toPropertyOfType propertyClass: AnyClass) -> Bool {
		if let valueClass = type(of: value) as? AnyClass, propertyClass.isSubclass(of: valueClass) {
			return true
		}
		
		// Value doesn't necessarily need to be an object in Swift.
		if (value is Int || value is Double) && propertyClass.isSubclass(of: NSNumber.self) {
			return true
		}
		
		if (value is String) && propertyClass.isSubclass(of: NSString.self) {
			return true
		}
		
		if (value is Date) && propertyClass.isSubclass(of: NSDate.self) {
			return true
		}
		
		if let obj = value as? NSObject {
			return propertyClass.isSubclass(of: type(of: obj))
		}
		
		return false
	}
	
	fileprivate func _property(forObject object: XUJSONDeserializable, andKey key: String) -> XUObjCProperty? {
		let classIdentifier = ObjectIdentifier(type(of: object))

		_cacheLock.lock()
		defer {
			_cacheLock.unlock()
		}

		if _cachedProperties[classIdentifier] == nil {
			let properties = XUObjCProperty.properties(on: type(of: object), includingSuperclasses: true)
			var propertyMapping: [String : XUObjCProperty] = [:]
			for prop in properties {
				propertyMapping[prop.name] = prop
				propertyMapping[prop.name.lowercased()] = prop
			}
			
			_cachedProperties[classIdentifier] = propertyMapping
		}
		
		let properties = _cachedProperties[classIdentifier]!
		if let property = properties[key] {
			return property
		}
		
		let lowercaseKey = key.lowercased()
		if let property = properties[lowercaseKey] {
			// Matching lowercase.
			_cachedProperties[classIdentifier]![lowercaseKey] = property
			return property
		}

		return nil
	}

	fileprivate func _deserializeObject(_ object: XUJSONDeserializable, fromDictionary dictionary: XUJSONDictionary, underKey key: String) -> XUJSONDeserializationPropertyResult {
		if object.ignoreKey?(key) ?? false {
			return .ignored
		}

		let property: XUObjCProperty
		if let propertyName = object.propertyNameForDictionaryRepresentationKey?(key) {
			// Custom name
			guard let prop = self._property(forObject: object, andKey: propertyName) else {
				self._addLogEntry(.error, objectClass: type(of: object), key: key, additionalInformation: "Property named \(propertyName) not found in class \(type(of: object))")
				return .error
			}

			property = prop
		} else {
			
			/// First, give chance to custom deserialization.
			let value = dictionary[key]
			if let dict = value as? XUJSONDictionary {
				if object.performCustomDeserializationOfObject?(dict, forKey: key) ?? false {
					return .customDeserializationPerformed
				}
			} else if let array = value as? [Any] {
				if object.performCustomDeserializationOfObjects?(array, forKey: key) ?? false {
					return .customDeserializationPerformed
				}
			}
			
			// We need to find it.
			guard let prop = self._property(forObject: object, andKey: key) else {
				self._addLogEntry(.warning, objectClass: type(of: object), key: key, additionalInformation: "Key \(key) not handled when mapping class \(type(of: object))")
				return .unhandled(error: .warning)
			}

			property = prop
		}
		
		if (reservedProperties.contains(property.name) || property.isReadOnly) {
			self._addLogEntry(.error, objectClass: type(of: object), key: key, additionalInformation: "Property named \(property.name) on class \(type(of: object)) is READ-ONLY or RESERVED")
			return .error
		}
		
		var response: XUJSONDeserializationPropertyResult = .deserializedValue(property: property, value: nil, error: .error)
		_exceptionHandler.perform({
			var dontSet: Bool = false
			let localResponse = self._transformedValue(dictionary[key]!, forKey: key, onObject: object, toProperty: property, dontSetValue: &dontSet)
			if dontSet {
				response = .customDeserializationPerformed
				return // Handled by custom deserialization
			}
			
			response = .deserializedValue(property: property, value: localResponse.value, error: localResponse.error)
		}, withCatchHandler: { (exception) in
			self._addLogEntry(.error, objectClass: type(of: object), key: key, additionalInformation: "Failed setting value for key \(key) to property \(property.name) on class \(type(of: object)), exception \(exception)")
			
			response = .error
		}, andFinallyBlock: {})

		return response
	}
	
	fileprivate func _fetchOrCreateObjectForDictionary(_ value: XUJSONDictionary, forKey key: String, onObject object: XUJSONDeserializable, toProperty property: XUObjCProperty) -> (value: Any?, error: XUJSONDeserializationError) {
		
		/// Fetching the object.
		
		if let entityID = object.entityIDInDictionary?(value, forKey: key) {
			if let entity = object.fetchEntityWithID?(entityID, forKey: key) {
				return (entity, .none)
			}
		}
		
		/// Creating the object.
		
		if object.createObjectForKey == nil {
			self._addLogEntry(.error, objectClass: type(of: object), key: key, additionalInformation: "The class \(type(of: object)) doesn't implement createObjectForKey(:_)!")
			return (nil, .error)
		}
		
		guard let obj = object.createObjectForKey?(key) else {
			self._addLogEntry(.error, objectClass: type(of: object), key: key, additionalInformation: "Cannot create object from dictionary under key \(key) on class \(type(of: object)).")
			return (nil, .error)
		}
		
		return (obj, .none)
	}
	
	fileprivate func _transformedArray(_ value: [Any], forKey key: String, onObject object: XUJSONDeserializable, toArrayLikeProperty property: XUObjCProperty, dontSetValue: inout Bool) -> (value: Any?, error: XUJSONDeserializationError) {
		let transformedArrayResult = self._transformedArray(value, forKey: key, onObject: object, toProperty: property, dontSetValue: &dontSetValue)
		if dontSetValue { // A custom deserialization took place
			return (nil, .none)
		}
		
		guard let array = transformedArrayResult.value else {
			return (transformedArrayResult.value, transformedArrayResult.error)
		}
		
		let result: Any
		if let setType = property.propertyClass as? NSSet.Type {
			result = setType.init(array: array)
		} else if let setType = property.propertyClass as? NSOrderedSet.Type {
			result = setType.init(array: array)
		} else if let _ = property.propertyClass as? NSArray.Type {
			result = array
		} else {
			// Unknown target class
			self._addLogEntry(.error, objectClass: type(of: object), key: key, additionalInformation: "Unknown array-like class. (\(property.propertyClass.descriptionWithDefaultValue()))")
			return (nil, .error)
		}
		
		return (result, transformedArrayResult.error) // Pass the warning
	}
	
	fileprivate func _transformedArray(_ value: [Any], forKey key: String, onObject object: XUJSONDeserializable, toProperty property: XUObjCProperty, dontSetValue: inout Bool) -> (value: [Any]?, error: XUJSONDeserializationError) {
		if value.count == 0 {
			return ([], .none)
		}
		
		let firstObject = value.first!
		if firstObject is String || firstObject is NSNumber {
			// List of IDs
			if let result = object.mapIDs?(value, toObjectsForKey: key) {
				return (result, .none)
			}
			
			if object.performCustomDeserializationOfObjects?(value, forKey: key) ?? false {
				dontSetValue = true
				return (nil, .none)
			}
			
			self._addLogEntry(.warning, objectClass: type(of: object), key: key, additionalInformation: "Cannot map object for key \(key) on class \(type(of: object)).")
			return (nil, .warning)
		}
		
		if let dicts = value as? [XUJSONDictionary] {
			if object.performCustomDeserializationOfObjects?(value, forKey: key) ?? false {
				dontSetValue = true
				return (nil, .none)
			}
			
			let result = dicts.flatMap({ (dict) -> Any? in
				guard let obj = self._fetchOrCreateObjectForDictionary(dict, forKey: key, onObject: object, toProperty: property).value else {
					return nil // Can be some filtering.
				}
				
				if let deserializableObject = obj as? XUJSONDeserializable {
					if self.deserializeObject(deserializableObject, fromDictionary: dict) != .none {
						return nil
					}
				}
				return obj
			})
			
			/// TODO: Add warning if any objects were skipped? Return .Error if
			/// .Error was returned by deserializeObject?
			
			return (result, .none)
		}
		
		self._addLogEntry(.error, objectClass: type(of: object), key: key, additionalInformation: "Cannot convert value of class \(type(of: value)) to \(property.propertyClass.descriptionWithDefaultValue()). (\(value))")
		return (nil, .error)
	}
	
	fileprivate func _transformedDictionary(_ value: XUJSONDictionary, forKey key: String, onObject object: XUJSONDeserializable, toProperty property: XUObjCProperty, dontSetValue: inout Bool) -> (value: Any?, error: XUJSONDeserializationError) {
		if property.propertyClass!.isSubclass(of: NSDictionary.self) {
			// Keep it the dictionary
			return (value, .none)
		}

		let response = self._fetchOrCreateObjectForDictionary(value, forKey: key, onObject: object, toProperty: property)
		if let deserializable = response.value as? XUJSONDeserializable {
			self.deserializeObject(deserializable, fromDictionary: value)
		}
		return response
	}
	
	fileprivate func _transformedScalarValue(_ value: Any, forObject object: XUJSONDeserializable, andKey key: String) -> (value: Any?, error: XUJSONDeserializationError) {
		// We need a NSNumber
		if value is NSNull {
			return (value: nil, error: .none)
		}
		
		if value is NSNumber {
			return (value: value, error: .none)
		}
		
		guard let str = value as? String else {
			self._addLogEntry(.error, objectClass: type(of: object), key: key, additionalInformation: "Cannot convert value of class \(type(of: value)) to scalar type.")
			return (value: nil, error: .error)
		}
		
		/// Bool value
		if str.hasCaseInsensitive(prefix: "t") || str.hasCaseInsensitive(prefix: "y") {
			// true / yes
			return (value: true, error: .none)
		} else if str.hasCaseInsensitive(prefix: "f") || str.hasCaseInsensitive(prefix: "n") {
			// false / no
			return (value: false, error: .none)
		}
		
		/// The value may be a date mapping on NSTimeInterval.
		if object.dateFromString != nil {
			if let date = object.dateFromString!(str, forKey: key) {
				return (value: date, error: .none)
			}
		} else {
			if let date = Date.date(withISO8601: str, andReturnError: nil) {
				return (value: date, error: .none)
			}
		}
		
		let doubleValue = str.doubleValue
		if doubleValue == 0.0 && !str.hasPrefix("0") {
			self._addLogEntry(.error, objectClass: type(of: object), key: key, additionalInformation: "Cannot convert string '\(str)' to scalar type.")
			return (value: nil, error: .error)
		}
		
		return (value: doubleValue, error: .none)
	}
	
	fileprivate func _transformValueToDate(_ value: Any, forObject object: XUJSONDeserializable, andKey key: String) -> (value: Any?, error: XUJSONDeserializationError) {
		if value is Date {
			// Already a date
			return (value, .none)
		}
		
		if let number = value as? NSNumber {
			return (Date(timeIntervalSince1970: TimeInterval(number.doubleValue)), .none)
		}
		
		guard let str = value as? String else {
			self._addLogEntry(.error, objectClass: type(of: object), key: key, additionalInformation: "Cannot convert value of class \(type(of: value)) to date.")
			return (value: nil, error: .error)
		}
		
		let dateOptional: Date?
		if object.dateFromString != nil {
			dateOptional = object.dateFromString!(str, forKey: key)
		} else {
			dateOptional = Date.date(withISO8601: str, andReturnError: nil)
		}

		guard let date = dateOptional else {
			self._addLogEntry(.warning, objectClass: type(of: object), key: key, additionalInformation: "Cannot convert string '\(str)' to date.")
			return (nil, .warning)
		}
		
		return (date, .none)
	}
	
	fileprivate func _transformValueToNumber(_ value: Any, forObject object: XUJSONDeserializable, andKey key: String) -> (value: Any?, error: XUJSONDeserializationError) {
		/// Value isn't NSNumber, since that would have already been handled in 
		/// _transformedValue(...).
		guard let str = value as? String else {
			self._addLogEntry(.error, objectClass: type(of: object), key: key, additionalInformation: "Cannot convert value of class \(type(of: value)) to number.")
			return (value: nil, error: .error)
		}

		let doubleValue = str.doubleValue
		if doubleValue == 0.0 && !str.hasPrefix("0") {
			self._addLogEntry(.error, objectClass: type(of: object), key: key, additionalInformation: "Cannot convert string '\(str)' to scalar type.")
			return (value: nil, error: .error)
		}
		
		return (value: doubleValue, error: .none)
	}
	
	fileprivate func _transformValueToDecimalNumber(_ value: Any, forObject object: XUJSONDeserializable, andKey key: String) -> (value: Any?, error: XUJSONDeserializationError) {
		if let number = value as? NSNumber {
			return (NSDecimalNumber.decimalNumber(withNumber: number), .none)
		}
		
		if let str = value as? String {
			return (NSDecimalNumber(string: str), .none)
		}
		
		self._addLogEntry(.error, objectClass: type(of: object), key: key, additionalInformation: "Cannot convert value of class \(type(of: value)) to decimal number.")
		return (value: nil, error: .error)
	}
	
	fileprivate func _transformedValue(_ value: Any, forKey key: String, onObject object: XUJSONDeserializable, toProperty property: XUObjCProperty, dontSetValue: inout Bool) -> (value: Any?, error: XUJSONDeserializationError) {
		if let dictionary = value as? XUJSONDictionary {
			if object.performCustomDeserializationOfObject?(dictionary, forKey: key) ?? false {
				dontSetValue = true
				return (value: nil, error: .none)
			}
		}
		
		if let customTransformation = object.transformedValue?(value, forKey: key) {
			return (value: customTransformation, error: .none)
		}
		
		if property.isScalar {
			return self._transformedScalarValue(value, forObject: object, andKey: key)
		}
		
		// Now that the value isn't scalar, let's handle the basic transformations.
		
		// Value is of the same class as property.
		guard let propertyClass = property.propertyClass else {
			self._addLogEntry(.error, objectClass: type(of: object), key: key, additionalInformation: "Property declared on \(type(of: object)) contains an unknown class \(property.className ?? "<>").")
			return (value: nil, error: .error)
		}
		
		// Arrays get handled differently
		let valueType: AnyClass? = type(of: value) as? AnyClass
		if propertyClass != NSArray.self && self._canAssign(value, toPropertyOfType: propertyClass) {
			return (value: value, error: .none)
		}
		
		if value is NSNull {
			return (value: nil, error: .none)
		}
		
		if propertyClass == Date.self || propertyClass == NSDate.self {
			return self._transformValueToDate(value, forObject: object, andKey: key)
		}
		
		if propertyClass == NSNumber.self {
			return self._transformValueToNumber(value, forObject: object, andKey: key)
		}
		
		if propertyClass == NSDecimalNumber.self {
			return self._transformValueToDecimalNumber(value, forObject: object, andKey: key)
		}
		
		// Convert arrays to all array-like properties
		if let array = value as? [Any], propertyClass.isSubclass(of: NSArray.self) || propertyClass.isSubclass(of: NSSet.self) || propertyClass.isSubclass(of: NSOrderedSet.self) {
			return self._transformedArray(array, forKey: key, onObject: object, toArrayLikeProperty: property, dontSetValue: &dontSetValue)
		}
		
		if let dict = value as? XUJSONDictionary {
			return self._transformedDictionary(dict, forKey: key, onObject: object, toProperty: property, dontSetValue: &dontSetValue)
		}
		
		self._addLogEntry(.error, objectClass: type(of: object), key: key, additionalInformation: "Cannot convert value of class \(type(of: value)) to \(propertyClass) - \(value).")
		return (nil, .error)


	}

	/// Deserialized the object from the dictionary. Initial attempt is that it
	/// goes through all the keys of the dictionary and calls
	/// propertyNameForDictionaryRepresentationKey(_:) and if it gets a non-nil
	/// response, it automatically assigns the value, if it supported (NSString,
	/// NSNumber, ...).
	///
	/// If no non-standard mappings are required, you do not need to override
	/// this method.
	///
	/// Smart mapping:
	/// - there are some default type conversions NSString <-> NSNumber,
	///				NSString/NSNumber <-> NSDate. You can modify the behavior in
	///				transformedValue(_:forKey:).
	/// - if the value under the particular key is an Array, it is further
	///				looked into it. If it contains NSStrings or NSNumbers,
	///				mapIDs(_:toObjectsForKey:) is called. If dictionaries are present,
	///				createObjectForKey(_:) is called and if a non-nil object is
	///				returned, the array is mapped. If neither condition is met,
	///				performCustomDeserializationOfObject[s](_:forKey:) is called.
	///
	/// @note - The implementation will lock the context for NSMangedObject
	/// subclasses. The locking may be expensive since it performs the updates
	/// on a different thread (usually). If the context is set for main queue,
	/// deserialize the object on main thread (which saves a lot of unnecessary 
	/// context switches). The deserializer has a built-in support for this,
	/// avoiding UI lock-up by letting one-pass run loop after deserializing each
	/// object.
	@discardableResult
	public func deserializeObject(_ object: XUJSONDeserializable, fromDictionary dictionary: XUJSONDictionary) -> XUJSONDeserializationError {
		var result: XUJSONDeserializationError = .none
		
		var values: [XUObjCProperty : Any?] = [:]
		for key in dictionary.keys {
			let resultPerKey = self._deserializeObject(object, fromDictionary: dictionary, underKey: key)
			switch resultPerKey {
			case .customDeserializationPerformed: fallthrough
			case .ignored:
				continue
			case .error:
				result = .error
			case .unhandled(let error):
				if error.isMoreSevere(than: result) {
					result = error
				}
			case .deserializedValue(let property, let value, let error):
				if error.isMoreSevere(than: result) {
					result = error
				}
				
				if error != .error {
					values[property] = value
				}
			}
		}
		
		// Now, set the values on the object. This deferred set has a major
		// advantage of only performing one locked block on managed objects.
		if let managedObject = object as? NSManagedObject, let moc = managedObject.managedObjectContext {
			moc.performAndWait {
				for (property, value) in values {
					// We're trying to prevent creating relationships between
					// different contexts.
					if let object = value as? NSManagedObject, object.managedObjectContext != moc {
						continue
					} else if let set = value as? NSSet, let objectsInSet = set.allObjects as? [NSManagedObject] {
						let objectsInSameMOC = objectsInSet.filter({ $0.managedObjectContext == moc })
						object.setValue(NSSet(array: objectsInSameMOC), forKey: property.name)
					} else if let set = value as? NSOrderedSet, let objectsInSet = set.array as? [NSManagedObject] {
						let objectsInSameMOC = objectsInSet.filter({ $0.managedObjectContext == moc })
						object.setValue(NSOrderedSet(array: objectsInSameMOC), forKey: property.name)
					} else {
						object.setValue(value, forKey: property.name)
					}
				}
			}
		} else {
			for (property, value) in values {
				object.setValue(value, forKey: property.name)
			}
		}
		
		object.objectWasDeserializedFromDictionary?(dictionary)
		
		/// This is a slight hack that allows a fast deserialization on main 
		/// thread. See the note in this method's docs. 
		if Thread.isMainThread {
			CFRunLoopRunInMode(CFRunLoopMode.defaultMode, 0, false)
		}

		return result
	}

	/// Optionally, you can create your own copy of the deserializer.
	public init() {
		// No-op
	}
}

public final class XUJSONDeserializationLogEntry: CustomDebugStringConvertible {

	/// Severity of the issue. May be only .Warning or .Error
	public let severity: XUJSONDeserializationError

	/// Object that was being deserialized.
	public let objectClass: AnyClass

	/// Key, for which the issue occurred.
	public let key: String

	/// Additional information about the issue.
	public let additionalInformation: String
	
	public var debugDescription: String {
		return "\(self.severity): \(objectClass).\(key): \(additionalInformation)"
	}

	public init(severity: XUJSONDeserializationError, objectClass: AnyClass, key: String, additionalInformation: String = "") {
		self.severity = severity
		self.objectClass = objectClass
		self.key = key
		self.additionalInformation = additionalInformation
	}
}
