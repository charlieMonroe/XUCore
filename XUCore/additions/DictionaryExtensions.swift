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
public typealias XUJSONDictionary = Dictionary<String, AnyObject>

/// Introducing the += function for dictionaries
public func += <KeyType, ValueType> (inout left: Dictionary<KeyType, ValueType>, right: Dictionary<KeyType, ValueType>) {
	for (k, v) in right {
		left.updateValue(v, forKey: k)
	}
}


public extension Dictionary {
	
	/// A convenience method for retrieving an array of dictionaries
	public func arrayOfDictionariesForKeyPath(keyPath: String) -> [XUJSONDictionary]? {
		return self.arrayOfDictionariesForKeyPaths(keyPath)
	}
	
	/// A convenience method for retrieving an array of dictionaries
	public func arrayOfDictionariesForKeyPaths(keyPaths: String...) -> [XUJSONDictionary]? {
		return self.firstNonNilObjectForKeyPaths(keyPaths, ofClass: [XUJSONDictionary].self)
	}
	
	/// Returns boolean value for key. If the value is Bool itself, it is returned.
	/// If the value is NSNumber, boolean value of it is returned. False is
	/// returned otherwise.
	public func booleanForKey(key: Key) -> Bool {
		if let boolValue = self[key] as? Bool {
			return boolValue
		}
		
		if let numberObj = self[key] as? NSNumber {
			return numberObj.boolValue
		}
		
		return false
	}
	
	/// See booleanForKey. Except here the argument is keyPath.
	public func booleanForKeyPath(keyPath: String) -> Bool {
		if let boolValue = self.objectForKeyPath(keyPath) as? Bool {
			return boolValue
		}
		
		if let numberObj = self.objectForKeyPath(keyPath) as? NSNumber {
			return numberObj.boolValue
		}
		
		return false
	}
	
	/// A convenience method for retrieving dictionaries.
	public func dictionaryForKeyPath(keyPath: String) -> XUJSONDictionary? {
		return self.objectForKeyPath(keyPath) as? XUJSONDictionary
	}
	
	/// A convenience method for retrieving dictionaries.
	public func dictionaryForKeyPaths(keyPaths: String...) -> XUJSONDictionary? {
		for keyPath in keyPaths {
			if let d = self.dictionaryForKeyPath(keyPath) {
				return d
			}
		}
		return nil
	}
	
	/// In a lot of cases, currently we need to get an int from whatever is under
	/// the key in the dictionary. Unfortunately, getting an optional Double? sucks
	/// when dealing with ObjC as well, since ObjC doesn't have optionals. So, simply
	/// 0 is fine when the value cannot be determined.
	public func doubleForKey(key: Key) -> Double {
		if let numberObj = self[key] as? NSNumber {
			return numberObj.doubleValue
		}
		
		if let stringObj = self[key] as? String {
			return stringObj.doubleValue
		}
		
		return 0
	}
	
	
	// MARK: first[*] family of methods
	
	/********** THIS METHOD CAUSES THE COMPILER TO CRASH. *******************/
	/// See objectForKeyPath - this method attempts to find the first non-nil
	/// object of class. Works as something between objectForKeyPath and
	/// firstNonNilObjectForKeys.
	//public func firstNonNilObjectForKeyPaths<T>(keyPaths: String..., ofClass aClass: T.Type) -> T? {
	//	return self.firstNonNilObjectForKeyPaths(keyPaths, ofClass: aClass)
	//}
	
	/// See objectForKeyPath - this method attempts to find the first non-nil
	/// object of class. Works as something between objectForKeyPath and
	/// firstNonNilObjectForKeys.
	public func firstNonNilObjectForKeyPaths<T>(keyPaths: [String], ofClass aClass: T.Type) -> T? {
		for path in keyPaths {
			if let v = self.objectForKeyPath(path) as? T {
				return v
			}
		}
		return nil
	}
	
	/// A convenience method for firstNonNilObjectForKeyPaths defaulting to AnyObject
	public func firstNonNilObjectForKeyPaths(keyPaths: String...) -> AnyObject? {
		return self.firstNonNilObjectForKeyPaths(keyPaths, ofClass: AnyObject.self)
	}
	
	/// Returns first non-nil value of a certain class under one of the keys.
	public func firstNonNilObjectForKeys<T>(keys: [Key], ofClass aClass: T.Type) -> T? {
		for k in keys {
			if let v = self[k] as? T {
				return v
			}
		}
		return nil
	}

	/// Returns first non-nil string value for key paths.
	public func firstNonNilStringForKeyPaths(keyPaths: [String]) -> String? {
		return self.firstNonNilObjectForKeyPaths(keyPaths, ofClass: String.self)
	}
	
	/// Returns first non-nil string value for key paths.
	public func firstNonNilStringForKeyPaths(keyPaths: String...) -> String? {
		return self.firstNonNilObjectForKeyPaths(keyPaths, ofClass: String.self)
	}
	
	/// Returns first non-nil string value for keys.
	public func firstNonNilStringForKeys(keys: [Key]) -> String? {
		return self.firstNonNilObjectForKeys(keys, ofClass: String.self)
	}
	
	/// Returns first non-nil string value for keys.
	public func firstNonNilStringForKeys(keys: Key...) -> String? {
		return self.firstNonNilObjectForKeys(keys, ofClass: String.self)
	}
	
	/// In a lot of cases, currently we need to get an int from whatever is under
	/// the key in the dictionary. Unfortunately, getting an optional UInt? sucks
	/// when dealing with ObjC as well, since ObjC doesn't have optionals. So, simply
	/// 0 is fine when the value cannot be determined.
	public func integerForKey(key: Key) -> Int {
		if let numberObj = self[key] as? NSNumber {
			return numberObj.integerValue
		}
		
		if let stringObj = self[key] as? String {
			return stringObj.integerValue
		}
		
		return 0
	}
	
	/// @see integerForKey.
	public func integerForKeyPath(keyPath: String) -> Int {
		guard let obj = self.objectForKeyPath(keyPath) else {
			return 0
		}
		
		if let numberObj = obj as? NSNumber {
			return numberObj.integerValue
		}
		
		if let stringObj = obj as? String {
			return stringObj.integerValue
		}
		
		return 0
	}
	
	/// This method returns an object at keyPath, safely, by casting and doing
	/// bounds checking. This works pretty much the same as info extraction
	/// in XUDownloader.
	///
	/// The keyPath isn't like in the rest of Cocoa dot-separated, but has the
	/// following format: [key1][0][key2][key3]
	public func objectForKeyPath(keyPath: String) -> Any? {
		let components = keyPath.stringByTrimmingCharactersInSet(NSCharacterSet(charactersInString: "[]")).componentsSeparatedByString("][")
		
		var obj: Any? = self
		for key in components {
			if let dict = obj as? XUJSONDictionary {
				obj = dict[key]
			}else if let arr = obj as? [AnyObject] {
				let index = Int(key)
				if index == nil {
					print("Dictionary.objectForKeyPath(): Index \(key) cannot be applied on an array!")
					return nil
				}
				
				if index! < arr.count {
					obj = arr[index!]
				}else{
					return nil
				}
			}else{
				return nil
			}
		}
		
		return obj
	}
	
	/// Most of the time, you need to use objectForKeyPath for getting end nodes
	/// in JSON dictionaries, which are strings. This method allows is
	/// a convenience method that allows you to get the string without casting.
	public func stringForKeyPath(keyPath: String) -> String? {
		return self.objectForKeyPath(keyPath) as? String
	}
	
	/// This will put together all key-value pairs as key1=value1&key2=value2&...,
	/// percent encoding the value. If the value is not of NSString class - description
	/// is called on that object.
	public var URLQueryString: String {
		var keyValuePairs: [String] = [ ]
		for (key,value) in self {
			let charSet = NSCharacterSet.alphanumericCharacterSet()
			let stringKey = (key as? String) ?? "INVALID KEY"
			let encodedKey = stringKey.stringByAddingPercentEncodingWithAllowedCharacters(charSet) ?? ""
			let valueObject: AnyObject = (value as? AnyObject) ?? "INVALID VALUE"
			let encodedValue = (valueObject.description ?? "UNKNOWN DESCRIPTION").stringByAddingPercentEncodingWithAllowedCharacters(charSet) ?? ""
			
			keyValuePairs.append("\(encodedKey)=\(encodedValue)")
		}
		
		return keyValuePairs.joinWithSeparator("&")
	}
	
}
