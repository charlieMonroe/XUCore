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

private enum KeyPathPart {
	case optional([String])
	case required([String])
}

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

public struct KeyPathOptions: OptionSet {
	
	public let rawValue: Int
	
	public static let notEmpty = KeyPathOptions(rawValue: 1 << 0)
	
	public static let all: [KeyPathOptions] = [.notEmpty]
	
	public init(rawValue: Int) {
		self.rawValue = rawValue
	}
	
}

extension Dictionary {
	
	private func _collection<T: Collection>(forKeyPath keyPath: String, options: KeyPathOptions) -> T? {
		guard let value = self.firstNonNilValue(ofType: T.self, forKeyPaths: keyPath) else {
			return nil
		}
		
		if options.contains(.notEmpty) {
			guard !value.isEmpty else {
				return nil
			}
		}
		
		return value
	}
	
	
	public func arrayOfDictionaries(forKeyPath keyPath: String) -> [XUJSONDictionary]? {
		return self.arrayOfDictionaries(forKeyPath: keyPath, options: [])
	}
	
	/// A convenience method for retrieving an array of dictionaries
	public func arrayOfDictionaries(forKeyPath keyPath: String, options: KeyPathOptions) -> [XUJSONDictionary]? {
		return self._collection(forKeyPath: keyPath, options: options)
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
	
	public func dictionary(forKeyPath keyPath: String) -> XUJSONDictionary? {
		return self.dictionary(forKeyPath: keyPath, options: [])
	}
	
	/// A convenience method for retrieving dictionaries.
	public func dictionary(forKeyPath keyPath: String, options: KeyPathOptions) -> XUJSONDictionary? {
		return self._collection(forKeyPath: keyPath, options: options)
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
	
	
	public func string(forKeyPath keyPath: String) -> String? {
		return self.string(forKeyPath: keyPath, options: [])
	}
	
	/// Most of the time, you need to use value(forKeyPath:) for getting end nodes
	/// in JSON dictionaries, which are strings. This method allows is
	/// a convenience method that allows you to get the string without casting.
	public func string(forKeyPath keyPath: String, options: KeyPathOptions) -> String? {
		return self._collection(forKeyPath: keyPath, options: options)
	}
	
	private func _parseKeyPath(_ originalKeyPath: String) -> [KeyPathPart] {
		guard originalKeyPath.hasPrefix("[") else {
			// Consider the whole thing a key.
			return [.required([originalKeyPath])]
		}
		
		var keyPath = Substring(originalKeyPath)
		
		var components: [KeyPathPart] = []
		while let index = keyPath.firstIndex(of: Character("]")) {
			let part = keyPath[keyPath.startIndex ... index].dropFirst().dropLast()
			let isOptional: Bool
			if index != keyPath.index(keyPath.endIndex, offsetBy: -1) {
				isOptional = keyPath[keyPath.index(index, offsetBy: 1)] == Character("?")
			} else {
				isOptional = false
			}
			
			if isOptional {
				keyPath = keyPath[keyPath.index(index, offsetBy: 2)...]
			} else {
				keyPath = keyPath[keyPath.index(index, offsetBy: 1)...]
			}
			
			var keys: [String]
			if part.first == Character("("), part.last == Character(")") {
				keys = part.dropFirst().dropLast().components(separatedBy: "|")
			} else {
				keys = [String(part)]
			}
			
			components.append(isOptional ? .optional(keys) : .required(keys))
		}
		
		return components
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
	/// For arrays, if you don't know the index, you can use `?` as a placeholder and
	/// all values will be searched. E.g. `[key1][?][key2]` will search the entire
	/// array under `key1` for a value that contains `key2`.
	///
	/// Additionally, you can use regex for keys by prefixing it with "r'": [r'regex].
	/// This can currently only be used as a single key, cannot be in a group
	/// with variations (i.e. [(r'regex1|r'regex2)] will not be interpretted as regexes).
	///
	/// For array indexes, you can use -1 for the last index.
	public func value(forKeyPath keyPath: String) -> Any? {
		let components = self._parseKeyPath(keyPath)
		return self._value(for: components)
	}
	
	private func _value<C: Collection>(for components: C) -> Any? where C.Element == KeyPathPart, C.Index == Int {
		var obj: Any? = self
		for (index, originalKey) in components.enumerated() {
			let isOptional: Bool
			let keys: [String]
			
			switch originalKey {
			case .optional(let array):
				isOptional = true
				keys = array
			case .required(let array):
				isOptional = false
				keys = array
			}
						
			if let dict = obj as? XUJSONDictionary {
				let value: Any?
				if keys.count == 1 {
					if keys[0].hasPrefix("r'") {
						let regex = keys[0].deleting(prefix: "r'")
						if let regexMatchedValue = dict.first(where: { $0.key.matches(regex: regex) })?.value {
							value = regexMatchedValue
						} else {
							value = nil
						}
					} else {
						value = dict[keys[0]]
					}
				} else {
					value = dict.firstNonNilValue(ofType: Any.self, forKeys: keys)
				}
				
				if value == nil, isOptional {
					continue
				} else {
					obj = value
				}
			} else if let arr = obj as? [Any] {
				let indexes: [Int]
				if keys.count == 1, keys[0] == "?" {
					guard index + 1 < components.count else {
						XULog("Dictionary.objectForKeyPath(): Wild card [?] array index cannot be used as the last component! Returning nil.")
						return nil
					}
					
					let dictionaries = arr.compactCast(to: [String : Any].self)
					let pathSuffix = components.suffix(from: index + 1)
					for dictionary in dictionaries {
						if let value = dictionary._value(for: pathSuffix) {
							return value
						}
					}

					// The wild card failed, we have no value, returning nil.
					return nil
				} else {
					indexes = keys.compactMap(Int.init(_:))
				}
				guard indexes.count == keys.count else {
					XULog("Dictionary.objectForKeyPath(): Indexes \(keys) cannot be applied on an array!")
					return nil
				}
				
				guard let index = indexes.first(where: { $0 == -1 || $0 < arr.count }) else {
					XULog("None of the indexes \(indexes) can be applied on array of \(arr.count) elements.")
					return nil
				}
				
				let value: Any?
				if index == -1 {
					value = arr.last
				} else if index < arr.count {
					value = arr[index]
				} else {
					value = nil
				}
				
				if value == nil, isOptional {
					continue
				} else {
					obj = value
				}
			} else {
				if let obj = obj {
					XULog("Key \(originalKey) cannot be applied on \(type(of: obj))")
					
					if isOptional {
						continue
					}
				}
				return nil
			}
		}
		
		return obj
	}
	
}

extension Dictionary where Key == String {
	
	private func _urlQueryDictionary(sorted: Bool) -> String {
		var keyValuePairs: [String] = []
		for (key, value) in sorted ? self.sorted(by: { $0.key < $1.key }) : Array(self) {
			let stringKey = key
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
	
	/// This will put together all key-value pairs as key1=value1&key2=value2&...,
	/// percent encoding the value. If the value is not a String - description
	/// is called on that object.
	///
	/// Unlike urlQueryString, this sorts the parameters by name.
	public var sortedURLQueryString: String {
		return self._urlQueryDictionary(sorted: true)
	}
	
	/// This will put together all key-value pairs as key1=value1&key2=value2&...,
	/// percent encoding the value. If the value is not a String - description
	/// is called on that object.
	public var urlQueryString: String {
		return self._urlQueryDictionary(sorted: false)
	}
	
}
