//
//  XUJSONDeserializable.swift
//  XUCore
//
//  Created by Charlie Monroe on 2/13/17.
//  Copyright © 2017 Charlie Monroe Software. All rights reserved.
//

import Foundation


/// All classes that want to be deserialized by the deserializer must conform to
/// this protocol. @objc is required for CoreData.
@objc public protocol XUJSONDeserializable: AnyObject {
	
	/// This is implemented by NSObject. If you are not basing your class on
	/// NSObject, you need to do this yourself.
	func setValue(_ value: Any?, forKey: String)
	
	/// This method is called when the deserializer encounters a dictionary under
	/// `key`. The returned object doesn't necessarily need to conform to
	/// XUJSONDeserializable - it can be e.g. String.
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
	@objc optional func createObject(forKey key: String) -> Any?
	
	/// Dates are tricky to deserialize since JSON doesn't specify a format for
	/// them. The default implementation assumes ISO8601 format and tries to
	/// deserialize it. You can customize this behavior.
	@objc optional func date(from dateString: String, forKey key: String) -> Date?
	
	/// The serializer supports updating already existing entities from fetched
	/// content. When the serializer encounters a dictionary, it asks for the
	/// entityID. If a non-nil object is returned, fetchEntityWithID(_:forKey:)
	/// is invoked.
	///
	/// @note - the `key` parameter refers to the the key currently being deserialized.
	@objc optional func entityID(in dictionary: XUJSONDictionary, forKey key: String) -> Any?
	
	/// entityIDInDictionary(_:forKey:) returned a non-nil value which is passed
	/// as `entityID` parameter here. You should return the entity with this ID.
	///
	/// @note - the `key` parameter refers to the the key currently being deserialized.
	@objc optional func fetchEntity(withID entityID: Any, forKey key: String) -> Any?
	
	/// Return true if you want to ignore this key. If true is returned, the
	/// deserializer will not call any further methods.
	@objc optional func ignoreKey(_ key: String) -> Bool
	
	/// You can observe the fact that you were deserialized by implementing this
	/// method.
	@objc optional func objectWasDeserialized(from dictionary: XUJSONDictionary)
	
	/// When the deserializer encounters an array of strings or numbers (NSNumber),
	/// it will call this method assuming that those are IDs or some other objects.
	/// The default implementation returns nil.
	@objc optional func mapIDs(_ IDs: [Any], toObjectsForKey key: String) -> [Any]?
	
	/// When the createObject(forKey:) method returns nil, the deserializer
	/// calls this method. Return true to indicate that the custom deserialization
	/// was successful, false that it was not.
	@objc optional func performCustomDeserialization(ofObject object: XUJSONDictionary, forKey key: String) -> Bool
	
	/// When the createObjectForKey(_:) method returns nil, the deserializer
	/// calls this method. Return true to indicate that the custom deserialization
	/// was successful, false that it was not.
	@objc optional func performCustomDeserialization(ofObjects objects: [Any], forKey key: String) -> Bool
	
	/// Returns the name of the property for that particular key. By default,
	/// if nil is returned, the deserializer goes through the class' properties
	/// and finds one that is a case-insensitive match.
	@objc optional func propertyName(forDictionaryKey key: String) -> String?
	
	/// Transforms the value to the representation required by the class. Return
	/// nil if you don't want transformation for that key to occur.
	@objc optional func transformedValue(_ value: Any?, forKey key: String) -> Any?
	
}
