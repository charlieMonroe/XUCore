//
//  XUJSONDeserializer.swift
//  XUCore
//
//  Created by Charlie Monroe on 2/23/16.
//  Copyright © 2016 Charlie Monroe Software. All rights reserved.
//

import CoreData
import Foundation

/// We're caching the properties, since they are likely to be often reused.
private var _cachedProperties: [String : [XUObjCProperty]] = [:]
private var _cacheLock: NSLock = NSLock(name: "com.charliemonroe.XUJSONDeserialization.XUObjCPropertyCache")


/// Reserved read-only properties used by Foundation/CoreData.
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
	case None

	/// The deserialization was successful with minor warnings, for example, the
	/// dictionary contained a key that was not handled by the deserializer, nor
	/// the XUJSONDeserializable object (i.e. it can't find a property, yet
	/// ignoreKey(_:) returns false.
	case Warning

	/// A fatal error has occurred when deserializing the object. This can for
	/// example be if the setValue(_:forKey:) method throws an exception because
	/// you are setting e.g. a NSNumber into a NSString property.
	case Error

	public func isMoreSevereThan(otherError: XUJSONDeserializationError) -> Bool {
		if otherError == self {
			return false
		}

		if self == .None {
			return false
		}

		if self == .Warning {
			return otherError != .Error
		}

		return true
	}
}

/// All classes that want to be deserialized by the deserializer must conform to
/// this protocol.
@objc public protocol XUJSONDeserializable: AnyObject {
	
	/// This is implemented by NSObject. If you are not basing your class on 
	/// NSObject, you need to do this yourself.
	func setValue(value: AnyObject?, forKey: String)

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
	optional func createObjectForKey(key: String) -> AnyObject?

	/// Dates are tricky to deserialize since JSON doesn't specify a format for
	/// them. The default implementation assumes ISO8601 format and tries to
	/// deserialize it. You can customize this behavior.
	optional func dateFromString(dateString: String, forKey key: String) -> NSDate?
	
	/// The serializer supports updating already existing entities from fetched
	/// content. When the serializer encounters a dictionary, it asks for the
	/// entityID. If a non-nil object is returned, fetchEntityWithID(_:forKey:)
	/// is invoked.
	///
	/// @note - the `key` parameter refers to the the key currently being deserialized.
	optional func entityIDInDictionary(dictionary: XUJSONDictionary, forKey key: String) -> AnyObject?

	/// entityIDInDictionary(_:forKey:) returned a non-nil value which is passed
	/// as `entityID` parameter here. You should return the entity with this ID.
	///
	/// @note - the `key` parameter refers to the the key currently being deserialized.
	optional func fetchEntityWithID(entityID: AnyObject, forKey key: String) -> AnyObject?
	
	/// Return true if you want to ignore this key. If true is returned, the
	/// deserializer will not call any further methods.
	optional func ignoreKey(key: String) -> Bool
	
	/// You can observe the fact that you were deserialized by implementing this
	/// method.
	optional func objectWasDeserializedFromDictionary(dictionary: XUJSONDictionary)

	/// When the deserializer encounters an array of strings or numbers (NSNumber),
	/// it will call this method assuming that those are IDs or some other objects.
	/// The default implementation returns nil.
	optional func mapIDs(IDs: [AnyObject], toObjectsForKey key: String) -> [AnyObject]?

	/// When the createObjectForKey(_:) method returns nil, the deserializer
	/// calls this method. Return true to indicate that the custom deserialization
	/// was successful, false that it was not.
	optional func performCustomDeserializationOfObject(object: XUJSONDictionary, forKey key: String) -> Bool

	/// When the createObjectForKey(_:) method returns nil, the deserializer
	/// calls this method. Return true to indicate that the custom deserialization
	/// was successful, false that it was not.
	optional func performCustomDeserializationOfObjects(objects: [AnyObject], forKey key: String) -> Bool

	/// Returns the name of the property for that particular key. By default,
	/// if nil is returned, the deserializer goes through the class' properties
	/// and finds one that is a case-insensitive match.
	optional func propertyNameForDictionaryRepresentationKey(key: String) -> String?

	/// Transforms the value to the representation required by the class. By default
	/// just returns the value.
	optional func transformedValue(value: AnyObject?, forKey key: String) -> AnyObject?
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
public class XUJSONDeserializer {

	private static let XUJSONDeserializerThreadKey = "XUJSONDeserializerThreadKey"

	/// Returns the default deserializer. Each thread has its own instance that
	/// is lazily created.
	public class var defaultDeserializer: XUJSONDeserializer {
		let threadDictionary = NSThread.currentThread().threadDictionary
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
	public static var deserializationLoggingEnabled: Bool = XUApplicationSetup.sharedSetup.isRunningInDebugMode

	/// Exception catcher.
	private let _exceptionHandler = XUExceptionHandler()

	/// Deserialization log. This will contain all the warnings and errors. Only
	/// populated if deserializationLoggingEnabled is true. Remember that the
	/// deserializer is provided on per-thread basis, so each time the thread dies,
	/// the log dies with it.
	public private(set) var deserializationLog: [XUJSONDeserializationLogEntry] = []

	/// You can set logging enabled per deserializer. By default contains the
	/// global option.
	public var isLoggingEnabled: Bool = XUJSONDeserializer.deserializationLoggingEnabled

	private func _addLogEntry(severity: XUJSONDeserializationError, objectClass: AnyClass, key: String, additionalInformation: String = "") {
		if !self.isLoggingEnabled {
			return
		}
		
		let entry = XUJSONDeserializationLogEntry(severity: severity, objectClass: objectClass, key: key, additionalInformation: additionalInformation)
		self.deserializationLog.append(entry)
		XULog(entry.debugDescription)
	}
	
	private func _propertiesForObject(object: XUJSONDeserializable) -> [XUObjCProperty] {
		let className = NSStringFromClass(object.dynamicType)

		_cacheLock.lock()
		defer {
			_cacheLock.unlock()
		}

		if let properties = _cachedProperties[className] {
			return properties
		}

		let properties = XUObjCProperty.propertiesOnClass(object.dynamicType, includingSuperclasses: true)
		_cachedProperties[className] = properties
		return properties
	}

	private func _deserializeObject(object: XUJSONDeserializable, fromDictionary dictionary: XUJSONDictionary, underKey key: String) -> XUJSONDeserializationError {
		if object.ignoreKey?(key) ?? false {
			return .None
		}

		let propertyList = self._propertiesForObject(object)
		let property: XUObjCProperty
		if let propertyName = object.propertyNameForDictionaryRepresentationKey?(key) {
			// Custom name
			guard let prop = propertyList.find({ $0.name.isCaseInsensitivelyEqualToString(propertyName)}) else {
				self._addLogEntry(.Error, objectClass: object.dynamicType, key: key, additionalInformation: "Property named \(propertyName) not found in class \(object.dynamicType)")
				return .Error
			}

			property = prop
		} else {
			// We need to find it.
			guard let prop = propertyList.find({ $0.name.isCaseInsensitivelyEqualToString(key)}) else {
				let value = dictionary[key]
				if let dict = value as? XUJSONDictionary {
					if object.performCustomDeserializationOfObject?(dict, forKey: key) ?? false {
						return .None
					}
				} else if let array = value as? [AnyObject] {
					if object.performCustomDeserializationOfObjects?(array, forKey: key) ?? false {
						return .None
					}
				}

				self._addLogEntry(.Warning, objectClass: object.dynamicType, key: key, additionalInformation: "Key \(key) not handled when mapping class \(object.dynamicType)")
				return .Warning
			}

			property = prop
		}
		
		if (reservedProperties.contains(property.name) || property.isReadOnly) {
			self._addLogEntry(.Error, objectClass: object.dynamicType, key: key, additionalInformation: "Property named \(property.name) on class \(object.dynamicType) is READ-ONLY or RESERVED")
			return .Error
		}
		
		var response: (value: AnyObject?, error: XUJSONDeserializationError) = (nil, .Error)
		_exceptionHandler.performBlock({
			var dontSet: Bool = false
			response = self._transformedValue(dictionary[key]!, forKey: key, onObject: object, toProperty: property, dontSetValue: &dontSet)
			if dontSet {
				return // Handled by custom deserialization
			}
			
			if let managedObject = object as? NSManagedObject {
				managedObject.managedObjectContext?.performBlockAndWait {
					object.setValue(response.value, forKey: property.name)
				}
			} else {
				object.setValue(response.value, forKey: property.name)
			}
		}, withCatchHandler: { (exception) in
			self._addLogEntry(.Error, objectClass: object.dynamicType, key: key, additionalInformation: "Failed setting value for key \(key) to property \(property.name) on class \(object.dynamicType), exception \(exception)")
			
			response.error = .Error
		}, andFinallyBlock: {})

		return response.error
	}
	
	private func _fetchOrCreateObjectForDictionary(value: XUJSONDictionary, forKey key: String, onObject object: XUJSONDeserializable, toProperty property: XUObjCProperty) -> (value: AnyObject?, error: XUJSONDeserializationError) {
		
		/// Fetching the object.
		
		if let entityID = object.entityIDInDictionary?(value, forKey: key) {
			if let entity = object.fetchEntityWithID?(entityID, forKey: key) {
				return (entity, .None)
			}
		}
		
		/// Creating the object.
		
		if object.createObjectForKey == nil {
			self._addLogEntry(.Error, objectClass: object.dynamicType, key: key, additionalInformation: "The class \(object.dynamicType) doesn't implement createObjectForKey(:_)!")
			return (nil, .Error)
		}
		
		guard let obj = object.createObjectForKey?(key) else {
			self._addLogEntry(.Error, objectClass: object.dynamicType, key: key, additionalInformation: "Cannot create object from dictionary under key \(key) on class \(object.dynamicType).")
			return (nil, .Error)
		}
		
		return (obj, .None)
	}
	
	private func _transformedArray(value: [AnyObject], forKey key: String, onObject object: XUJSONDeserializable, toArrayLikeProperty property: XUObjCProperty, inout dontSetValue: Bool) -> (value: AnyObject?, error: XUJSONDeserializationError) {
		let transformedArrayResult = self._transformedArray(value, forKey: key, onObject: object, toProperty: property, dontSetValue: &dontSetValue)
		if dontSetValue { // A custom deserialization took place
			return (nil, .None)
		}
		
		guard let array = transformedArrayResult.value else {
			return (transformedArrayResult.value, transformedArrayResult.error)
		}
		
		let result: AnyObject
		if let setType = property.propertyClass as? NSSet.Type {
			result = setType.init(array: array)
		} else if let setType = property.propertyClass as? NSOrderedSet.Type {
			result = setType.init(array: array)
		} else if let _ = property.propertyClass as? NSArray.Type {
			result = array
		} else {
			// Unknown target class
			self._addLogEntry(.Error, objectClass: object.dynamicType, key: key, additionalInformation: "Unknown array-like class. (\(property.propertyClass))")
			return (nil, .Error)
		}
		
		return (result, transformedArrayResult.error) // Pass the warning
	}
	
	private func _transformedArray(value: [AnyObject], forKey key: String, onObject object: XUJSONDeserializable, toProperty property: XUObjCProperty, inout dontSetValue: Bool) -> (value: [AnyObject]?, error: XUJSONDeserializationError) {
		if value.count == 0 {
			return ([], .None)
		}
		
		let firstObject = value.first!
		if firstObject is String || firstObject is NSNumber {
			// List of IDs
			if let result = object.mapIDs?(value, toObjectsForKey: key) {
				return (result, .None)
			}
			
			if object.performCustomDeserializationOfObjects?(value, forKey: key) ?? false {
				dontSetValue = true
				return (nil, .None)
			}
			
			self._addLogEntry(.Warning, objectClass: object.dynamicType, key: key, additionalInformation: "Cannot map object for key \(key) on class \(object.dynamicType).")
			return (nil, .Warning)
		}
		
		if let dicts = value as? [XUJSONDictionary] {
			if object.performCustomDeserializationOfObjects?(value, forKey: key) ?? false {
				dontSetValue = true
				return (nil, .None)
			}
			
			if object.createObjectForKey == nil {
				self._addLogEntry(.Error, objectClass: object.dynamicType, key: key, additionalInformation: "The class \(object.dynamicType) doesn't implement createObjectForKey(:_)!")
				return (nil, .Error)
			}
			
			let result = dicts.filterMap({ (dict) -> AnyObject? in
				guard let obj = self._fetchOrCreateObjectForDictionary(dict, forKey: key, onObject: object, toProperty: property).value else {
					return nil // Can be some filtering.
				}
				
				if let deserializableObject = obj as? XUJSONDeserializable {
					if self.deserializeObject(deserializableObject, fromDictionary: dict) != .None {
						return nil
					}
				}
				return obj
			})
			
			/// TODO: Add warning if any objects were skipped? Return .Error if
			/// .Error was returned by deserializeObject?
			
			return (result, .None)
		}
		
		self._addLogEntry(.Error, objectClass: object.dynamicType, key: key, additionalInformation: "Cannot convert value of class \(value.dynamicType) to \(property.propertyClass). (\(value))")
		return (nil, .Error)
	}
	
	private func _transformedDictionary(value: XUJSONDictionary, forKey key: String, onObject object: XUJSONDeserializable, toProperty property: XUObjCProperty, inout dontSetValue: Bool) -> (value: AnyObject?, error: XUJSONDeserializationError) {
		if property.propertyClass!.isSubclassOfClass(NSDictionary.self) {
			// Keep it the dictionary
			return (value, .None)
		}

		let response = self._fetchOrCreateObjectForDictionary(value, forKey: key, onObject: object, toProperty: property)
		if let deserializable = response.value as? XUJSONDeserializable {
			self.deserializeObject(deserializable, fromDictionary: value)
		}
		return response
	}
	
	private func _transformedScalarValue(value: AnyObject, forObject object: XUJSONDeserializable, andKey key: String) -> (value: AnyObject?, error: XUJSONDeserializationError) {
		// We need a NSNumber
		if value is NSNull {
			return (value: nil, error: .None)
		}
		
		if value is NSNumber {
			return (value: value, error: .None)
		}
		
		guard let str = value as? String else {
			self._addLogEntry(.Error, objectClass: object.dynamicType, key: key, additionalInformation: "Cannot convert value of class \(value.dynamicType) to scalar type.")
			return (value: nil, error: .Error)
		}
		
		/// Bool value
		if str.hasCaseInsensitivePrefix("t") || str.hasCaseInsensitivePrefix("y") {
			// true / yes
			return (value: true, error: .None)
		} else if str.hasCaseInsensitivePrefix("f") || str.hasCaseInsensitivePrefix("n") {
			// false / no
			return (value: false, error: .None)
		}
		
		/// The value may be a date mapping on NSTimeInterval.
		if object.dateFromString != nil {
			if let date = object.dateFromString!(str, forKey: key) {
				return (value: date, error: .None)
			}
		} else {
			if let date = NSDate.dateWithISO8601String(str, andReturnError: nil) {
				return (value: date, error: .None)
			}
		}
		
		let doubleValue = str.doubleValue
		if doubleValue == 0.0 && !str.hasPrefix("0") {
			self._addLogEntry(.Error, objectClass: object.dynamicType, key: key, additionalInformation: "Cannot convert string '\(str)' to scalar type.")
			return (value: nil, error: .Error)
		}
		
		return (value: doubleValue, error: .None)
	}
	
	private func _transformValueToDate(value: AnyObject, forObject object: XUJSONDeserializable, andKey key: String) -> (value: AnyObject?, error: XUJSONDeserializationError) {
		if value is NSDate {
			// Already a date
			return (value, .None)
		}
		
		if let number = value as? NSNumber {
			return (NSDate(timeIntervalSince1970: NSTimeInterval(number.doubleValue)), .None)
		}
		
		guard let str = value as? String else {
			self._addLogEntry(.Error, objectClass: object.dynamicType, key: key, additionalInformation: "Cannot convert value of class \(value.dynamicType) to date.")
			return (value: nil, error: .Error)
		}
		
		let dateOptional: NSDate?
		if object.dateFromString != nil {
			dateOptional = object.dateFromString!(str, forKey: key)
		} else {
			dateOptional = NSDate.dateWithISO8601String(str, andReturnError: nil)
		}

		guard let date = dateOptional else {
			self._addLogEntry(.Warning, objectClass: object.dynamicType, key: key, additionalInformation: "Cannot convert string '\(str)' to date.")
			return (nil, .Warning)
		}
		
		return (date, .None)
	}
	
	private func _transformValueToNumber(value: AnyObject, forObject object: XUJSONDeserializable, andKey key: String) -> (value: AnyObject?, error: XUJSONDeserializationError) {
		/// Value isn't NSNumber, since that would have already been handled in 
		/// _transformedValue(...).
		guard let str = value as? String else {
			self._addLogEntry(.Error, objectClass: object.dynamicType, key: key, additionalInformation: "Cannot convert value of class \(value.dynamicType) to number.")
			return (value: nil, error: .Error)
		}

		let doubleValue = str.doubleValue
		if doubleValue == 0.0 && !str.hasPrefix("0") {
			self._addLogEntry(.Error, objectClass: object.dynamicType, key: key, additionalInformation: "Cannot convert string '\(str)' to scalar type.")
			return (value: nil, error: .Error)
		}
		
		return (value: doubleValue, error: .None)
	}
	
	private func _transformValueToDecimalNumber(value: AnyObject, forObject object: XUJSONDeserializable, andKey key: String) -> (value: AnyObject?, error: XUJSONDeserializationError) {
		if let number = value as? NSNumber {
			return (NSDecimalNumber.decimalNumberWithNumber(number), .None)
		}
		
		if let str = value as? String {
			return (NSDecimalNumber(string: str), .None)
		}
		
		self._addLogEntry(.Error, objectClass: object.dynamicType, key: key, additionalInformation: "Cannot convert value of class \(value.dynamicType) to decimal number.")
		return (value: nil, error: .Error)
	}
	
	private func _transformedValue(value: AnyObject, forKey key: String, onObject object: XUJSONDeserializable, toProperty property: XUObjCProperty, inout dontSetValue: Bool) -> (value: AnyObject?, error: XUJSONDeserializationError) {
		if let dictionary = value as? XUJSONDictionary {
			if object.performCustomDeserializationOfObject?(dictionary, forKey: key) ?? false {
				dontSetValue = true
				return (value: nil, error: .None)
			}
		}
		
		if let customTransformation = object.transformedValue?(value, forKey: key) {
			return (value: customTransformation, error: .None)
		}
		
		if property.isScalar {
			return self._transformedScalarValue(value, forObject: object, andKey: key)
		}
		
		// Now that the value isn't scalar, let's handle the basic transformations.
		
		// Value is of the same class as property.
		guard let propertyClass = property.propertyClass else {
			self._addLogEntry(.Error, objectClass: object.dynamicType, key: key, additionalInformation: "Property declared on \(object.dynamicType) contains an unknown class \(property.className ?? "<>").")
			return (value: nil, error: .Error)
		}
		
		// Arrays get handled differently
		if propertyClass != NSArray.self && value.dynamicType.isSubclassOfClass(propertyClass) {
			return (value: value, error: .None)
		}
		
		if value is NSNull {
			return (value: nil, error: .None)
		}
		
		if propertyClass == NSDate.self {
			return self._transformValueToDate(value, forObject: object, andKey: key)
		}
		
		if propertyClass == NSNumber.self {
			return self._transformValueToNumber(value, forObject: object, andKey: key)
		}
		
		if propertyClass == NSDecimalNumber.self {
			return self._transformValueToDecimalNumber(value, forObject: object, andKey: key)
		}
		
		// Convert arrays to all array-like properties
		if let array = value as? [AnyObject] where propertyClass.isSubclassOfClass(NSArray.self) || propertyClass.isSubclassOfClass(NSSet.self) || propertyClass.isSubclassOfClass(NSOrderedSet.self) {
			return self._transformedArray(array, forKey: key, onObject: object, toArrayLikeProperty: property, dontSetValue: &dontSetValue)
		}
		
		if let dict = value as? XUJSONDictionary {
			return self._transformedDictionary(dict, forKey: key, onObject: object, toProperty: property, dontSetValue: &dontSetValue)
		}
		
		self._addLogEntry(.Error, objectClass: object.dynamicType, key: key, additionalInformation: "Cannot convert value of class \(value.dynamicType) to \(propertyClass) - \(value).")
		return (nil, .Error)


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
	/// NSString/NSNumber <-> NSDate. You can modify the behavior in
	/// transformedValue(_:forKey:).
	/// - if the value under the particular key is an Array, it is further
	/// looked into it. If it contains NSStrings or NSNumbers,
	/// mapIDs(_:toObjectsForKey:) is called. If dictionaries are present,
	/// createObjectForKey(_:) is called and if a non-nil object is
	/// returned, the array is mapped. If neither condition is met,
	/// performCustomDeserializationOfObject[s](_:forKey:) is called.
	public func deserializeObject(object: XUJSONDeserializable, fromDictionary dictionary: XUJSONDictionary) -> XUJSONDeserializationError {
		var result: XUJSONDeserializationError = .None
		for key in dictionary.keys {
			let resultPerKey = self._deserializeObject(object, fromDictionary: dictionary, underKey: key)
			object.objectWasDeserializedFromDictionary?(dictionary)
			
			if resultPerKey.isMoreSevereThan(result) {
				result = resultPerKey
			}
		}

		return result
	}

	/// Optionally, you can create your own copy of the deserializer.
	public init() {
		// No-op
	}
}

public class XUJSONDeserializationLogEntry: CustomDebugStringConvertible {

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
