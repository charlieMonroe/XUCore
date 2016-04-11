//
//  StringExtensions.swift
//  DownieCore
//
//  Created by Charlie Monroe on 8/6/15.
//  Copyright © 2015 Charlie Monroe Software. All rights reserved.
//

import Foundation

#if os(OSX)
	import Cocoa
#endif

public func + (lhs: String, rhs: Character) -> String {
	return lhs + String(rhs)
}

public func + (inout lhs: String, rhs: Character) {
	lhs = lhs + String(rhs)
}

public extension String {

	/// Creates a new UUID string.
	public static var UUIDString: String {
		let UIDRef = CFUUIDCreate(nil)
		let UID = CFUUIDCreateString(nil, UIDRef)
		return UID as String
	}

	/// Returns true if the other string is not empty and is contained in self
	/// case-insensitive.
	public func containsCaseInsensitiveString(otherString: String) -> Bool {
		if otherString.isEmpty {
			return false
		}
		return self.rangeOfString(otherString, options: .CaseInsensitiveSearch) != nil
	}

	/// Draws `self` centered in rect with attributes.
	public func drawCenteredInRect(rect: CGRect, withAttributes atts: [String: AnyObject]? = nil) -> CGRect {
		let stringSize = self.sizeWithAttributes(atts)
		self.drawAtPoint(CGPoint(x: rect.midX - stringSize.width / 2.0, y: rect.midY - stringSize.height / 2.0), withAttributes: atts)
		return CGRect(x: rect.midX - stringSize.width / 2.0, y: rect.midY - stringSize.height / 2.0, width: stringSize.width, height: stringSize.height)
	}

	/// Draws `self` aligned right to point.
	func drawRightAlignedToPoint(point: CGPoint, withAttributes atts: [String: AnyObject]? = nil) -> CGSize {
		let s = self.sizeWithAttributes(atts)
		self.drawAtPoint(CGPoint(x: point.x - s.width, y: point.y), withAttributes: atts)
		return s
	}

	/// Returns the first character or \0 if the string is empty.
	public var firstCharacter: Character {
		return self.characters.first ?? Character(UInt8(0))
	}

	/// Returns first line of string. Always non-nil
	public var firstLine: String {
		return self.componentsSeparatedByCharactersInSet(NSCharacterSet.newlineCharacterSet())[0]
	}

	/// This converts string to UInt as a fourCharCode
	public var fourCharCodeValue: Int {
		var result: Int = 0
		if let data = self.dataUsingEncoding(NSMacOSRomanStringEncoding) {
			let bytes = UnsafePointer<UInt8>(data.bytes)
			for i in 0 ..< data.length {
				result = result << 8 + Int(bytes[i])
			}
		}
		return result
	}

	/// Returns true if the receiver has prefix `prefix` in case-insensitive
	/// comparison.
	public func hasCaseInsensitivePrefix(prefix: String) -> Bool {
		guard let range = self.rangeOfString(prefix, options: .CaseInsensitiveSearch) else {
			return false
		}

		return range.startIndex == self.startIndex
	}

	/// Returns true if the receiver has `substring` in case-insensitive
	/// comparison.
	public func hasCaseInsensitiveSubstring(substring: String) -> Bool {
		return self.rangeOfString(substring, options: .CaseInsensitiveSearch) != nil
	}

	/// Returns true if the receiver has prefix `suffix` in case-insensitive
	/// comparison.
	public func hasCaseInsensitiveSuffix(suffix: String) -> Bool {
		guard let range = self.rangeOfString(suffix, options: .CaseInsensitiveSearch) else {
			return false
		}

		return range.endIndex == self.endIndex
	}

	/// Returns hexValue of the string.
	public var hexValue: Int {
		let components = self.componentsSeparatedByString("x")
		var suffix = components.count < 2 ? self : components[1]
		suffix = suffix.stringByTrimmingLeftCharactersInSet(NSCharacterSet(charactersInString: "0"))

		var result = 0
		for c in self.characters {
			if c >= Character("0") && c <= Character("9") {
				result *= 16
				result += Int(c.UTF8Value - Character("0").UTF8Value)
			} else if c >= Character("a") && c <= Character("f") {
				result *= 16
				result += Int(c.UTF8Value - Character("a").UTF8Value) + 10
			} else if c >= Character("A") && c <= Character("F") {
				result *= 16
				result += Int(c.UTF8Value - Character("A").UTF8Value) + 10
			} else {
				break
			}
		}
		return result
	}

	/// Replaces & -> &amp; etc.
	public var HTMLEscapedString: String {
		var string = self
		string = string.stringByReplacingOccurrencesOfString("&", withString: "&amp;", options: .LiteralSearch)
		string = string.stringByReplacingOccurrencesOfString("\"", withString: "&quot;", options: .LiteralSearch)
		string = string.stringByReplacingOccurrencesOfString("'", withString: "&#x27;", options: .LiteralSearch)
		string = string.stringByReplacingOccurrencesOfString(">", withString: "&gt;", options: .LiteralSearch)
		string = string.stringByReplacingOccurrencesOfString("<", withString: "&lt;", options: .LiteralSearch)
		return string
	}

	/// Replaces &amp; -> & etc.
	public var HTMLUnescapedString: String {
		var string = self
		string = string.stringByReplacingOccurrencesOfString("&nbsp;", withString: " ", options: .LiteralSearch)
		string = string.stringByReplacingOccurrencesOfString("&amp;", withString: "&", options: .LiteralSearch)
		string = string.stringByReplacingOccurrencesOfString("&quot;", withString: "\"", options: .LiteralSearch)
		string = string.stringByReplacingOccurrencesOfString("&#x27;", withString: "'", options: .LiteralSearch)
		string = string.stringByReplacingOccurrencesOfString("&#x39;", withString: "'", options: .LiteralSearch)
		string = string.stringByReplacingOccurrencesOfString("&#x92;", withString: "'", options: .LiteralSearch)
		string = string.stringByReplacingOccurrencesOfString("&#x96;", withString: "'", options: .LiteralSearch)
		string = string.stringByReplacingOccurrencesOfString("&gt;", withString: ">", options: .LiteralSearch)
		string = string.stringByReplacingOccurrencesOfString("&lt;", withString: "<", options: .LiteralSearch)
		string = string.stringByReplacingOccurrencesOfString("&apos;", withString: "'", options: .LiteralSearch)

		var i = 0
		while i < self.characters.count {
			let c = self.characters[self.characters.startIndex.advancedBy(i)]
			if c == Character("&") && i < self.characters.count - 1 {
				let nextC = self.characters[self.characters.startIndex.advancedBy(i + 1)]
				if nextC == Character("#") {
					var length = 0
					while i + length + 2 < self.characters.count {
						let cc = self.characters[self.characters.startIndex.advancedBy(i + length + 2)]
						if cc >= Character("0") && cc <= Character("9") {
							length += 1
							continue
						}
						break
					}

					let unicodeCharCode = self.substringWithRange(self.startIndex.advancedBy(i + 2) ..< self.startIndex.advancedBy(i + length + 2))
					let replacementChar = unicodeCharCode.integerValue
					string = string.stringByReplacingOccurrencesOfString("&#\(unicodeCharCode);", withString: String(format: "%C", replacementChar))
					i += 6
					continue
				}
			}
			i += 1
		}

		return string
	}
	
	/// Returns if the receiver is equal to the other string in a case
	/// insensitive manner.
	public func isCaseInsensitivelyEqualToString(string: String) -> Bool {
		return self.compare(string, options: .CaseInsensitiveSearch) == .OrderedSame
	}
	/// This tries to create a string from data. First, UTF8 is tried as encoding,
	/// then ASCII and then it just goes through the list of available string
	/// encodings. This is pretty much a convenience initializer for cases where
	/// you don't know the source encoding, but want to get a non-nil string
	/// for as many cases as possible.
	public init?(data: NSData!) {
		if data == nil {
			return nil
		}

		// First, try UTF8, then ASCII.
		for enc in [NSUTF8StringEncoding, NSASCIIStringEncoding] {
			if let str = String(data: data, encoding: enc) {
				self = str
				return
			}
		}

		var encodings = NSString.availableStringEncodings()
		while encodings.memory != 0 {
			let enc = encodings.memory as NSStringEncoding
			if let str = String(data: data, encoding: enc) {
				self = str
				return
			}

			encodings = encodings.successor()
		}

		return nil
	}

	/// Replaces \r, \n, \t, \u3245, etc.
	public var JSDecodedString: String {
		var result = self
		result = result.stringByReplacingOccurrencesOfString("\\r", withString: String(format: "%C", 13))
		result = result.stringByReplacingOccurrencesOfString("\\n", withString: String(format: "%C", 10))
		result = result.stringByReplacingOccurrencesOfString("\\t", withString: String(format: "%C", 9))

		var i: String.Index = self.startIndex
		while i < self.characters.endIndex {
			let c = self.characters[i]
			if c == Character("\\") && i < self.endIndex.advancedBy(-1) {
				let nextC = self.characters[i.successor()]
				if nextC == Character("u") && i < self.endIndex.advancedBy(-6) {
					let unicodeCharCode = self.substringWithRange(i.advancedBy(2) ..< i.advancedBy(6))
					let replacementChar = unicodeCharCode.hexValue
					
					result = result.stringByReplacingOccurrencesOfString("\\u\(unicodeCharCode)", withString: String(format: "%C", replacementChar))
					i = i.advancedBy(6)
					continue
				}
			}
			
			i = i.successor()
		}
		return result
	}

	/// Returns the last character or \0 if the string is empty.
	public var lastCharacter: Character {
		return self.characters.last ?? Character(UInt8(0))
	}
	
	/// Splits `self` using NSCharacterSet.newlineCharacterSet().
	public var lines: [String] {
		return self.componentsSeparatedByCharactersInSet(NSCharacterSet.newlineCharacterSet())
	}

	/// Computes MD5 digest of self
	public var MD5Digest: String {
		return (self as NSString).MD5Digest()
	}
	
	/// Truncates the string in the middle with '...' in order to fit the width, 
	/// similarily as NSTextField does.
	public func middleTruncatedStringToFitWidth(width: CGFloat, withAttributes atts: [String: AnyObject]) -> String {
		var front = ""
		var tail = ""
		
		var frontIndex = self.startIndex.advancedBy(self.characters.count / 2)
		var tailIndex = frontIndex
		
		var result = self
		var size = result.sizeWithAttributes(atts)
		while size.width > width {
			frontIndex = frontIndex.predecessor()
			tailIndex = tailIndex.successor()
			
			front = self.substringToIndex(frontIndex)
			tail = self.substringFromIndex(tailIndex)
			result = "\(front)...\(tail)"
			size = result.sizeWithAttributes(atts)
		}
		return result

	}

	/// Returns a reverse string.
	public var reverseString: String {
		return String(self.characters.reverse())
	}
	
	/// Returns second character, or \0 is the string has only one character (or
	/// is empty).
	public var secondCharacter: Character {
		if self.characters.count < 2 {
			return Character(UInt8(0))
		}
		
		return self.characters[self.startIndex.advancedBy(1)]
	}
	
	/// Returns size with attributes, limited to width.
	public func sizeWithAttributes(attrs: [String : AnyObject], maxWidth width: CGFloat) -> CGSize {
		let constraintSize = CGSize(width: width, height: CGFloat.max)
		#if os(iOS)
			return self.boundingRectWithSize(constraintSize, options: .UsesLineFragmentOrigin, attributes: attrs, context: nil).size
		#else
			return self.boundingRectWithSize(constraintSize, options: .UsesLineFragmentOrigin, attributes: attrs).size
		#endif
	}

	/// Capitalizes the first letter of the string.
	public var stringByCapitalizingFirstLetter: String {
		if self.characters.count == 0 {
			return self
		}

		let index = self.startIndex.advancedBy(1)
		let firstLetter = self.substringToIndex(index)
		let restOfString = self.substringFromIndex(index)
		return firstLetter.uppercaseString + restOfString
	}

	public var stringByDeletingLastCharacter: String {
		if self.isEmpty {
			fatalError("Cannot delete last character from an empty string!")
		}

		return self.substringToIndex(self.endIndex.predecessor())
	}

	/// Removes the prefix from the string.
	public func stringByDeletingPrefix(prefix: String) -> String {
		if !self.hasPrefix(prefix) {
			return self
		}

		return self.substringFromIndex(self.startIndex.advancedBy(prefix.characters.count))
	}

	/// Removes the suffix from the string.
	public func stringByDeletingSuffix(suffix: String) -> String {
		if !self.hasSuffix(suffix) {
			return self
		}

		let len = suffix.characters.count
		return self.substringToIndex(self.endIndex.advancedBy(-len))
	}

	/// Encodes string by adding percent escapes. Unlike
	/// stringByAddingPercentEncodingWithAllowedCharacters(...), this never
	/// returns nil, but instead falls back to self.
	public var stringByEncodingIllegalURLCharacters: String {
		return self.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.alphanumericCharacterSet()) ?? self
	}

	/// Lowercases the first letter of the string.
	public var stringByLowercasingFirstLetter: String {
		if self.characters.count == 0 {
			return self
		}

		let index = self.startIndex.advancedBy(1)
		let firstLetter = self.substringToIndex(index)
		let restOfString = self.substringFromIndex(index)
		return firstLetter.lowercaseString + restOfString
	}

	/// Trims the string to maximum length of maxLen, trimming the middle.
	public func stringByMiddleTrimmingToMaximumLengthOf(maxLen: Int) -> String {
		if self.characters.count < maxLen {
			return self
		}

		let begin = self.substringToIndex(self.startIndex.advancedBy((maxLen - 1) / 2))
		let end = self.substringFromIndex(self.endIndex.advancedBy(-1 * (maxLen - 1) / 2))
		return begin + "…" + end
	}

	/// Prepends prefix enough times so that it has the specific length.
	public func stringByPaddingFrontToLength(length: Int, withString padString: String) -> String {
		var str = self
		while str.characters.count + padString.characters.count < length {
			str = padString + str
		}
		return str
	}

	/// Trims whitespace characters
	public var stringByTrimmingWhitespace: String {
		return (self as NSString).stringByTrimmingWhitespace()
	}

	/// This method decodes the string as a URL query. E.g. arg1=val1&arg2=val2
	/// will become [ "arg1": "val1", ... ]. This is the opposite of URLQueryString()
	/// method on Dictionary
	public var URLQueryDictionary: [String: String] {
		let variablePairs = self.allVariablePairsForRegexString("&?(?P<VARNAME>[ ^=] +) = (?P<VARVALUE>[ ^ &] +) ")
		var dict: [String: String] = [:]
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

	/// This will return double value of the string, kind of like NSString in ObjC;
	/// if the string cannot be parsed, 0.0 is returned.
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
				} else {
					wasDot = true
				}
			}

			if char.isMemberOfCharacterSet(charSet) {
				numberString.append(char)
			} else {
				break
			}
		}

		return Double(numberString) ?? 0.0
	}

	/// This will return integer value of the string, kind of like NSString in ObjC;
	/// if the string cannot be parsed, 0 is returned.
	public var integerValue: Int {
		if let intValue = Int(self) {
			return intValue
		}

		let charSet = NSCharacterSet(charactersInString: "0123456789")
		var numberString = ""
		for char in self.characters {
			if char.isMemberOfCharacterSet(charSet) {
				numberString.append(char)
			} else {
				break
			}
		}

		return Int(numberString) ?? 0
	}
}
