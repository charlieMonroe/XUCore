//
//  DictionaryExtensions.swift
//  DownieCore
//
//  Created by Charlie Monroe on 8/10/15.
//  Copyright © 2015 Charlie Monroe Software. All rights reserved.
//

import Foundation


/// Since we keep casting AnyObject to this, it's easier to use a custom typealias
/// rather than keep typing out the generics.
public typealias XUJSONDictionary = Dictionary<String, Any>

public func + <KeyType, ValueType> (left: Dictionary<KeyType, ValueType>, right: Dictionary<KeyType, ValueType>) -> Dictionary<KeyType, ValueType> {
	var dict = left
	for (k, v) in right {
		dict.updateValue(v, forKey: k)
	}
	return dict
}

/// Introducing the += function for dictionaries
public func += <KeyType, ValueType> (left: inout Dictionary<KeyType, ValueType>, right: Dictionary<KeyType, ValueType>) {
	for (k, v) in right {
		left.updateValue(v, forKey: k)
	}
}

extension Dictionary where Key == String {
	
	/// This allows to define an enum Key: String and use it for the assignment.
	public subscript<T: RawRepresentable>(field: T) -> Value? where T.RawValue == String {
		get {
			return self[field.rawValue]
		}
		set {
			self[field.rawValue] = newValue
		}
	}
	
}


extension Dictionary {
	
	/// A convenience method for retrieving an array of dictionaries
	public func arrayOfDictionaries(forKeyPath keyPath: String) -> [XUJSONDictionary]? {
		return self.firstNonNilValue(ofType: [XUJSONDictionary].self, forKeyPaths: keyPath)
	}
	
	/// Returns boolean value for key. If the value is Bool itself, it is returned.
	/// If the value is NSNumber, boolean value of it is returned. False is
	/// returned otherwise.
	public func boolean(forKey key: Key) -> Bool {
		if let boolValue = self[key] as? Bool {
			return boolValue
		}
		
		if let numberObj = self[key] as? NSNumber {
			return numberObj.boolValue
		}
		
		return false
	}
	
	/// See booleanForKey. Except here the argument is keyPath.
	public func boolean(forKeyPath keyPath: String) -> Bool {
		guard let value = self.value(forKeyPath: keyPath) else {
			return false
		}
		
		if let boolValue = value as? Bool {
			return boolValue
		}
		
		if let numberObj = value as? NSNumber {
			return numberObj.boolValue
		}
		
		return false
	}
	
	/// A convenience method for retrieving dictionaries.
	public func dictionary(forKeyPath keyPath: String) -> XUJSONDictionary? {
		return self.value(forKeyPath: keyPath) as? XUJSONDictionary
	}
		
	/// In a lot of cases, currently we need to get an int from whatever is under
	/// the key in the dictionary. Unfortunately, getting an optional Double? sucks
	/// when dealing with ObjC as well, since ObjC doesn't have optionals. So, simply
	/// 0 is fine when the value cannot be determined.
	public func double(forKey key: Key) -> Double {
		if let double = self[key] as? Double {
			return double
		}
		
		if let numberObj = self[key] as? NSNumber {
			return numberObj.doubleValue
		}
		
		if let stringObj = self[key] as? String {
			return stringObj.doubleValue
		}
		
		return 0
	}
	
	/// In a lot of cases, currently we need to get an int from whatever is under
	/// the key in the dictionary. Unfortunately, getting an optional Double? sucks
	/// when dealing with ObjC as well, since ObjC doesn't have optionals. So, simply
	/// 0 is fine when the value cannot be determined.
	public func double(forKeyPath keyPath: String) -> Double {
		guard let value = self.value(forKeyPath: keyPath) else {
			return 0.0
		}
		
		if let double = value as? Double {
			return double
		}
		
		if let numberObj = value as? NSNumber {
			return numberObj.doubleValue
		}
		
		if let stringObj = value as? String {
			return stringObj.doubleValue
		}
		
		return 0.0
	}
	
	
	/// See value(forKeyPath:) - this method attempts to find the first
	/// non-nil value of T.
	public func firstNonNilValue<T>(ofType type: T.Type, forKeyPaths keyPaths: String...) -> T? {
		return self.firstNonNilValue(ofType: T.self, forKeyPaths: keyPaths)
	}
	
	/// See value(forKeyPath:) - this method attempts to find the first
	/// non-nil value of T.
	public func firstNonNilValue<T>(ofType type: T.Type, forKeyPaths keyPaths: [String]) -> T? {
		return keyPaths.firstNonNilValue(using: { self.value(forKeyPath: $0) as? T })
	}
	
	/// A convenience method for firstNonNilValue(forKeyPaths:) defaulting to Any.
	public func firstNonNilValue(forKeyPaths keyPaths: String...) -> Any? {
		return self.firstNonNilValue(ofType: Any.self, forKeyPaths: keyPaths)
	}
	
	/// Returns first non-nil value of a certain class under one of the keys.
	public func firstNonNilValue<T>(ofType type: T.Type, forKeys keys: Key...) -> T? {
		return self.firstNonNilValue(ofType: T.self, forKeys: keys)
	}
	
	/// Returns first non-nil value of a certain class under one of the keys.
	public func firstNonNilValue<T>(ofType type: T.Type, forKeys keys: [Key]) -> T? {
		return keys.firstNonNilValue(using: {
			// If T is Any, then even nil values will be infact non-nil... Which
			// is not correct as we'll return nonnil value for any key...
			let value = self[$0]
			guard value != nil else {
				return nil
			}
			
			return value as? T
		})
	}

	/// Returns first non-nil string value for key paths.
	public func firstNonNilString(forKeyPaths keyPaths: [String]) -> String? {
		return self.firstNonNilValue(ofType: String.self, forKeyPaths: keyPaths)
	}
	
	/// Returns first non-nil string value for key paths.
	public func firstNonNilString(forKeyPaths keyPaths: String...) -> String? {
		return self.firstNonNilValue(ofType: String.self, forKeyPaths: keyPaths)
	}
	
	/// Returns first non-nil string value for keys.
	public func firstNonNilString(forKeys keys: [Key]) -> String? {
		return self.firstNonNilValue(ofType: String.self, forKeys: keys)
	}
	
	/// Returns first non-nil string value for keys.
	public func firstNonNilString(forKeys keys: Key...) -> String? {
		return self.firstNonNilValue(ofType: String.self, forKeys: keys)
	}
	
	/// In a lot of cases, currently we need to get an int from whatever is under
	/// the key in the dictionary. Unfortunately, getting an optional UInt? sucks
	/// when dealing with ObjC as well, since ObjC doesn't have optionals. So, simply
	/// 0 is fine when the value cannot be determined.
	public func integer(forKey key: Key) -> Int {
		if let int = self[key] as? Int {
			return int
		}
		
		if let numberObj = self[key] as? NSNumber {
			return numberObj.intValue
		}
		
		if let stringObj = self[key] as? String {
			return stringObj.integerValue
		}
		
		return 0
	}
	
	/// @see integerForKey.
	public func integer(forKeyPath keyPath: String) -> Int {
		guard let obj = self.value(forKeyPath: keyPath) else {
			return 0
		}
		
		if let int = obj as? Int {
			return int
		}
		
		if let numberObj = obj as? NSNumber {
			return numberObj.intValue
		}
		
		if let stringObj = obj as? String {
			return stringObj.integerValue
		}
		
		return 0
	}
	
	/// Most of the time, you need to use value(forKeyPath:) for getting end nodes
	/// in JSON dictionaries, which are strings. This method allows is
	/// a convenience method that allows you to get the string without casting.
	public func string(forKeyPath keyPath: String) -> String? {
		return self.value(forKeyPath: keyPath) as? String
	}
	
	/// This will put together all key-value pairs as key1=value1&key2=value2&...,
	/// percent encoding the value. If the value is not a String - description
	/// is called on that object.
	public var urlQueryString: String {
		var keyValuePairs: [String] = []
		for (key, value) in self {
			let stringKey = (key as? String) ?? "INVALID KEY-\(key)"
			let encodedKey = stringKey.encodingIllegalURLCharacters
			if let array = value as? [CustomStringConvertible] {
				for v in array {
					let encodedValue = v.description.encodingIllegalURLCharacters
					keyValuePairs.append("\(encodedKey)[]=\(encodedValue)")
				}
			} else {
				let valueObject: CustomStringConvertible = (value as? CustomStringConvertible) ?? "INVALID VALUE-\(value)"
				let encodedValue = valueObject.description.encodingIllegalURLCharacters
				
				keyValuePairs.append("\(encodedKey)=\(encodedValue)")
			}
		}
		
		return keyValuePairs.joined(separator: "&")
	}
	
	/// This method returns an object at keyPath, safely, by casting and doing
	/// bounds checking.
	///
	/// The keyPath isn't like in the rest of Cocoa dot-separated, but has the
	/// following format: [key1][0][key2][key3]. XUCore will parse this and will
	/// apply the keys on arrays and dictionaries seemlessly.
	///
	/// You can also add key variations - example: [key1][(0|1)][(key2|key3)] will
	/// return [key1][0][key2] or [key1][1][key3], whichever is non-nil.
	///
	/// For array indexes, you can use -1 for the last index.
	public func value(forKeyPath keyPath: String) -> Any? {
		let components = keyPath.trimmingCharacters(in: CharacterSet(charactersIn: "[]")).components(separatedBy: "][")
		
		var obj: Any? = self
		for originalKey in components {
			var keys: [String]
			if originalKey.first == Character("("), originalKey.last == Character(")") {
				keys = originalKey.dropFirst().dropLast().components(separatedBy: "|")
			} else {
				keys = [originalKey]
			}
			
			
			if let dict = obj as? XUJSONDictionary {
				if keys.count == 1 {
					obj = dict[keys[0]]
				} else {
					obj = dict.firstNonNilValue(ofType: Any.self, forKeys: keys)
				}
			} else if let arr = obj as? [Any] {
				let indexes = keys.compactMap(Int.init(_:))
				guard indexes.count == keys.count else {
					XULog("Dictionary.objectForKeyPath(): Indexes \(keys) cannot be applied on an array!")
					continue
				}
				
				guard let index = indexes.first(where: { $0 == -1 || $0 < arr.count }) else {
					XULog("None of the indexes \(indexes) can be applied on array of \(arr.count) elements.")
					continue
				}
				
				if index == -1 {
					obj = arr.last
				} else if index < arr.count {
					obj = arr[index]
				} else {
					return nil
				}
			} else {
				return nil
			}
		}
		
		return obj
	}
	
}


/// Deprecated extensions.
extension Dictionary {
	
	@available(*, deprecated, message: "Use method with explicit type.")
	public func firstNonNilValue<T>(forKeys keys: [Key]) -> T? {
		return self.firstNonNilValue(ofType: T.self, forKeys: keys)
	}
	
	@available(*, deprecated, message: "Use method with explicit type.")
	public func firstNonNilValue<T>(forKeyPaths keyPaths: String...) -> T? {
		return self.firstNonNilValue(ofType: T.self, forKeyPaths: keyPaths)
	}
	
	@available(*, deprecated, message: "Use method with explicit type.")
	public func firstNonNilValue<T>(forKeyPaths keyPaths: [String]) -> T? {
		return self.firstNonNilValue(ofType: T.self, forKeyPaths: keyPaths)
	}
	
	@available(*, deprecated, message: "Use method with explicit type.")
	public func firstNonNilValue<T>(forKeys keys: Key...) -> T? {
		return self.firstNonNilValue(ofType: T.self, forKeys: keys)
	}
	
}

