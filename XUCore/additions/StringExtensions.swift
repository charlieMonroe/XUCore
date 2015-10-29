//
//  StringExtensions.swift
//  DownieCore
//
//  Created by Charlie Monroe on 8/6/15.
//  Copyright © 2015 Charlie Monroe Software. All rights reserved.
//

import Foundation

public extension String {
	
	public var firstLine: String {
		return self.componentsSeparatedByCharactersInSet(NSCharacterSet.newlineCharacterSet())[0]
	}
	
	
	public var fourCharCodeValue: UInt {
		var result: UInt = 0
		if let data = self.dataUsingEncoding(NSMacOSRomanStringEncoding) {
			let bytes = UnsafePointer<UInt8>(data.bytes)
			for i in 0..<data.length {
				result = result << 8 + UInt(bytes[i])
			}
		}
		return result
	}
	
	/** Returns hexValue of the string. */
	public var hexValue: UInt {
		return (self as NSString).hexValue()
	}
	
	/** Replaces & -> &amp; etc. */
	public var HTMLEscapedString: String {
		return (self as NSString).HTMLEscapedString()
	}
	
	/** Replaces &amp; -> & etc. */
	public var HTMLUnescapedString: String {
		return (self as NSString).HTMLUnescapedString()
	}
	
	public var JSDecodedString: String {
		return (self as NSString).JSDecodedString()
	}
	
	public var MD5Digest: String {
		return (self as NSString).MD5Digest()
	}
	
	public var reverseString: String {
		return String(self.characters.reverse())
	}
	
	public var stringByCapitalizingFirstLetter: String {
		if self.characters.count == 0 {
			return self
		}
		
		let index = self.startIndex.advancedBy(1)
		let firstLetter = self.substringToIndex(index)
		let restOfString = self.substringFromIndex(index)
		return firstLetter.uppercaseString + restOfString
	}
	
	/** Removes the prefix from the string. */
	public func stringByDeletingPrefix(prefix: String) -> String {
		if !self.hasPrefix(prefix) {
			return self
		}
		
		return self.substringFromIndex(self.startIndex.advancedBy(prefix.characters.count))
	}
	
	/** Removes the suffix from the string. */
	public func stringByDeletingSuffix(suffix: String) -> String {
		if !self.hasSuffix(suffix) {
			return self
		}
		
		let len = self.characters.count - 1
		return self.substringToIndex(self.startIndex.advancedBy(len))
	}
	
	/// Encodes string by adding percent escapes. Unlike
	/// stringByAddingPercentEncodingWithAllowedCharacters(...), this never 
	/// returns nil, but instead falls back to self.
	public var stringByEncodingIllegalURLCharacters: String {
		return self.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.alphanumericCharacterSet()) ?? self
	}
	
	/// Trims whitespace characters
	public var stringByTrimmingWhitespace: String {
		return (self as NSString).stringByTrimmingWhitespace()
	}

	/// This method decodes the string as a URL query. E.g. arg1=val1&arg2=val2
	/// will become [ "arg1": "val1", ... ]. This is the opposite of URLQueryString()
	/// method on Dictionary
	public var URLQueryDictionary: [String:String] {
		let variablePairs = self.allVariablePairsForRegexString("&?(?P<VARNAME>[^=]+)=(?P<VARVALUE>[^&]+)")
		var dict: [String:String] = [:]
		for (key, value) in variablePairs {
			guard let
					decodedKey = key.stringByRemovingPercentEncoding,
					decodedValue = value.stringByRemovingPercentEncoding else {
				dict[key] = value
				continue
			}
			
			dict[decodedKey] = decodedValue
		}
		return dict
	}
	
}


/// Numeric methods
public extension String {
	
	/** This will return double value of the string, kind of like NSString in ObjC;
	* if the string cannot be parsed, 0.0 is returned.
	*/
	public var doubleValue: Double {
		let doubleValue = Double(self)
		if doubleValue != nil {
			return doubleValue!
		}
		
		let charSet = NSCharacterSet(charactersInString: "0123456789.")
		var numberString = ""
		var wasDot = false
		for char in self.characters {
			if char == "." {
				if wasDot {
					break // Second dot
				}else{
					wasDot = true
				}
			}
			
			if char.isMemberOfCharacterSet(charSet) {
				numberString.append(char)
			}else{
				break
			}
		}
		
		return Double(numberString) ?? 0.0
	}
	
	/** This will return integer value of the string, kind of like NSString in ObjC;
	* if the string cannot be parsed, 0 is returned.
	*/
	public var integerValue: Int {
		if let intValue = Int(self) {
			return intValue
		}
		
		let charSet = NSCharacterSet(charactersInString: "0123456789")
		var numberString = ""
		for char in self.characters {
			if char.isMemberOfCharacterSet(charSet) {
				numberString.append(char)
			}else{
				break
			}
		}
		
		return Int(numberString) ?? 0
	}
	
}
