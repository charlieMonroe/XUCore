//
//  XUJSONHelper.swift
//  XUCore
//
//  Created by Charlie Monroe on 9/29/17.
//  Copyright © 2017 Charlie Monroe Software. All rights reserved.
//

import Foundation

/// XUJSONHelper defines a helper struct that defines various methods that allow
/// easier conversion between JSON and String.
public struct XUJSONHelper {

	/// Helper method that casts the object to XUJSONDictionary.
	public static func dictionary(from data: Data) -> XUJSONDictionary? {
		return self.object(from: data)
	}
	
	/// Helper method that casts the object to XUJSONDictionary.
	public static func dictionary(from jsonString: String) -> XUJSONDictionary? {
		return self.object(from: jsonString)
	}
	
	/// Helper method that casts the object to XUJSONDictionary.
	public static func dictionary(fromCallback jsonString: String) -> XUJSONDictionary? {
		return self.object(fromCallback: jsonString)
	}
	
	/// Converts json data to a JSON object.
	public static func object<T>(from data: Data) -> T? {
		guard let genericObj = try? JSONSerialization.jsonObject(with: data, options: []) else {
			XULog("Failed to parse JSON \(String(data: data).descriptionWithDefaultValue())")
			return nil
		}
		
		guard let obj = genericObj as? T else {
			XULog("Failed to cast JSON of type \(type(of: genericObj)) to \(T.self): \(genericObj).")
			return nil
		}
		
		return obj
	}
	
	/// Converts jsonString to a JSON object.
	public static func object<T>(from jsonString: String) -> T? {
		return self.object(from: jsonString.utf8Data)
	}
	
	/// Some JSON responses may contain secure prefixes - this method attempts
	/// to find the JSON potential callback function.
	public static func object<T>(fromCallback jsonString: String) -> T? {
		guard let innerJSON = jsonString.trimmingWhitespace.value(of: "JSON", inRegexes: "^([\\w\\.\\$]+)?\\((?P<JSON>.*)\\)", "/\\*-secure-\\s*(?P<JSON>{.*})", "^\\w+=(?P<JSON>{.*})") else {
			if jsonString.first == Character("{") && jsonString.last == Character("}") {
				return self.object(from: jsonString)
			}

			XULog("No inner JSON in callback string \(jsonString)")
			return nil
		}
		
		return self.object(from: innerJSON)
	}
	
	/// Returns a string from a JSON object. Returns nil if the object is not
	/// representable in JSON.
	public static func jsonString(from object: Any) -> String? {
		do {
			let data = try JSONSerialization.data(withJSONObject: object, options: [])
			return String(data: data)
		} catch let error {
			XULog("Failed to convert \(type(of: object)) to JSON: \(error).")
			return nil
		}
	}
	
	private init() {}
	
}
