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

/// + operator for String + Character
public func + (lhs: String, rhs: Character) -> String {
	return lhs + String(rhs)
}

/// + operator for String + Character
public func + (lhs: inout String, rhs: Character) {
	lhs = lhs + String(rhs)
}


public enum XUEmailValidationFormat {
	
	/// Correct format.
	case correct
	
	/// Wrong. Missing @ sign, etc.
	case wrong
	
	/// Phony. E.g. a@a.com.
	case phony
	
}


public extension String {

	/// Creates a new UUID string.
	public static var uuidString: String {
		let UIDRef = CFUUIDCreate(nil)
		let UID = CFUUIDCreateString(nil, UIDRef)
		return UID as! String
	}
	
	
	/// Decodes `self` as base64-encoded `NSData` and tries to create a string
	/// from the result.
	public var base64DecodedString: String? {
		guard let data = Data(base64Encoded: self, options: .ignoreUnknownCharacters) else {
			return nil
		}
		
		return String(data: data)
	}

	/// Returns true if the other string is not empty and is contained in self
	/// case-insensitive.
	@available(*, deprecated, renamed: "hasCaseInsensitive(substring:)")
	public func containsCaseInsensitiveString(_ otherString: String) -> Bool {
		if otherString.isEmpty {
			return false
		}
		return self.range(of: otherString, options: .caseInsensitive) != nil
	}

	/// Draws `self` centered in rect with attributes.
	@discardableResult
	public func draw(centeredIn rect: CGRect, withAttributes atts: [String: AnyObject]? = nil) -> CGRect {
		#if os(OSX)
			let stringSize = self.size(withAttributes: atts)
		#else
			let stringSize = (self as NSString).size(attributes: atts)
		#endif
		self.draw(at: CGPoint(x: rect.midX - stringSize.width / 2.0, y: rect.midY - stringSize.height / 2.0), withAttributes: atts)
		return CGRect(x: rect.midX - stringSize.width / 2.0, y: rect.midY - stringSize.height / 2.0, width: stringSize.width, height: stringSize.height)
	}

	/// Draws `self` aligned right to point.
	@discardableResult
	func draw(rightAlignedTo point: CGPoint, withAttributes atts: [String: AnyObject]? = nil) -> CGSize {
		#if os(OSX)
			let s = self.size(withAttributes: atts)
		#else
			let s = (self as NSString).size(attributes: atts)
		#endif
		self.draw(at: CGPoint(x: point.x - s.width, y: point.y), withAttributes: atts)
		return s
	}

	/// Returns the first character or \0 if the string is empty.
	public var firstCharacter: Character {
		return self.characters.first ?? Character(UInt8(0))
	}

	/// Returns first line of string. Always non-nil
	public var firstLine: String {
		return self.components(separatedBy: CharacterSet.newlines)[0]
	}

	/// This converts string to UInt as a fourCharCode
	public var fourCharCodeValue: Int {
		var result: Int = 0
		if let data = self.data(using: String.Encoding.macOSRoman) {
			let bytes = (data as NSData).bytes.bindMemory(to: UInt8.self, capacity: data.count)
			for i in 0 ..< data.count {
				result = result << 8 + Int(bytes[i])
			}
		}
		return result
	}

	/// Returns true if the receiver has prefix `prefix` in case-insensitive
	/// comparison.
	public func hasCaseInsensitive(prefix: String) -> Bool {
		guard let range = self.range(of: prefix, options: .caseInsensitive) else {
			return false
		}

		return range.lowerBound == self.startIndex
	}

	/// Returns true if the receiver has `substring` in case-insensitive
	/// comparison.
	public func hasCaseInsensitive(substring: String) -> Bool {
		return self.range(of: substring, options: .caseInsensitive) != nil
	}

	/// Returns true if the receiver has prefix `suffix` in case-insensitive
	/// comparison.
	public func hasCaseInsensitive(suffix: String) -> Bool {
		guard let range = self.range(of: suffix, options: .caseInsensitive) else {
			return false
		}

		return range.upperBound == self.endIndex
	}

	/// Returns hexValue of the string.
	public var hexValue: Int {
		let components = self.components(separatedBy: "x")
		var suffix = components.count < 2 ? self : components[1]
		suffix = suffix.trimmingLeftCharacters(in: CharacterSet(charactersIn: "0"))

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
		string = string.replacingOccurrences(of: "&", with: "&amp;", options: .literal)
		string = string.replacingOccurrences(of: "\"", with: "&quot;", options: .literal)
		string = string.replacingOccurrences(of: "'", with: "&#x27;", options: .literal)
		string = string.replacingOccurrences(of: ">", with: "&gt;", options: .literal)
		string = string.replacingOccurrences(of: "<", with: "&lt;", options: .literal)
		
		return string
	}

	/// Replaces &amp; -> & etc.
	public var HTMLUnescapedString: String {
		var string = self
		string = string.replacingOccurrences(of: "&nbsp;", with: " ", options: .literal)
		string = string.replacingOccurrences(of: "&amp;", with: "&", options: .literal)
		string = string.replacingOccurrences(of: "&quot;", with: "\"", options: .literal)
		string = string.replacingOccurrences(of: "&gt;", with: ">", options: .literal)
		string = string.replacingOccurrences(of: "&lt;", with: "<", options: .literal)
		string = string.replacingOccurrences(of: "&apos;", with: "'", options: .literal)
		string = string.replacingOccurrences(of: "&reg;", with: "®", options: .literal)

		let regex = XURegex(pattern: "&#(?P<C>x?[0-9a-f]+);", andOptions: .caseless)
		let allOccurrences = self.allValues(ofVariableNamed: "C", forRegex: regex).distinct()
		for occurrence in allOccurrences {
			let value: Int
			if occurrence.hasPrefix("x") {
				// Hex
				value = occurrence.deleting(prefix: "x").hexValue
			} else {
				value = occurrence.integerValue
			}
			
			string = string.replacingOccurrences(of: "&#\(occurrence);", with: String(Character(UnicodeScalar(value)!)))
		}
		
		return string
	}
	
	/// Returns if the receiver is equal to the other string in a case
	/// insensitive manner.
	public func isCaseInsensitivelyEqual(to string: String) -> Bool {
		return self.compare(string, options: .caseInsensitive) == .orderedSame
	}
	
	/// Creates self from a base64 encoded string.
	public init?(base64EncodedString: String) {
		guard let data = Data(base64Encoded: base64EncodedString, options: NSData.Base64DecodingOptions()) else {
			return nil
		}
		
		self.init(data: data)
	}
	
	/// This tries to create a string from data. First, UTF8 is tried as encoding,
	/// then ASCII and then it just goes through the list of available string
	/// encodings. This is pretty much a convenience initializer for cases where
	/// you don't know the source encoding, but want to get a non-nil string
	/// for as many cases as possible.
	public init?(data: Data!) {
		if data == nil {
			return nil
		}

		// First, try UTF8, then ASCII.
		for enc in [String.Encoding.utf8, String.Encoding.ascii] {
			if let str = String(data: data, encoding: enc) {
				self = str
				return
			}
		}

		for enc in String.availableStringEncodings {
			if let str = String(data: data, encoding: enc) {
				self = str
				return
			}
		}

		return nil
	}

	/// Replaces \r, \n, \t, \u3245, etc.
	public var JSDecodedString: String {
		var result = self
		result = result.replacingOccurrences(of: "\\r", with: String(Character(UnicodeScalar(13))))
		result = result.replacingOccurrences(of: "\\n", with: String(Character(UnicodeScalar(10))))
		result = result.replacingOccurrences(of: "\\t", with: String(Character(UnicodeScalar(9))))

		var i: String.Index = self.startIndex
		while i < self.characters.endIndex {
			let c = self.characters[i]
			if c == Character("\\") && i < self.characters.index(self.endIndex, offsetBy: -1) {
				let nextC = self.characters[self.characters.index(after: i)]
				if nextC == Character("u") && i < self.characters.index(self.endIndex, offsetBy: -6) {
					let unicodeCharCode = self.substring(with: self.characters.index(i, offsetBy: 2) ..< self.characters.index(i, offsetBy: 6))
					let replacementChar = unicodeCharCode.hexValue
					
					result = result.replacingOccurrences(of: "\\u\(unicodeCharCode)", with: String(Character(UnicodeScalar(replacementChar)!)))
					i = self.characters.index(i, offsetBy: 6)
					continue
				}
			}
			
			i = self.characters.index(after: i)
		}
		return result
	}

	/// Returns the last character or \0 if the string is empty.
	public var lastCharacter: Character {
		return self.characters.last ?? Character(UInt8(0))
	}
	
	/// Splits `self` using NSCharacterSet.newlineCharacterSet().
	public var lines: [String] {
		return self.components(separatedBy: CharacterSet.newlines)
	}

	/// Computes MD5 digest of self
	public var md5Digest: String {
		guard let data = self.data(using: String.Encoding.utf8) else {
			fatalError("Can't represent string as UTF8 - \(self).")
		}
		
		return data.md5Digest
	}
	
	public var sha1Digest: String {
		guard let data = self.data(using: String.Encoding.utf8) else {
			fatalError("Can't represent string as UTF8 - \(self).")
		}
		
		return data.sha1Digest
	}
	
	public var sha512Digest: String {
		guard let data = self.data(using: String.Encoding.utf8) else {
			fatalError("Can't represent string as UTF8 - \(self).")
		}
		
		return data.sha512Digest
	}
	
	/// Truncates the string in the middle with '...' in order to fit the width, 
	/// similarily as NSTextField does.
	public func truncatingMiddle(toFitWidth width: CGFloat, withAttributes atts: [String: AnyObject]) -> String {
		var front = ""
		var tail = ""
		
		var frontIndex = self.characters.index(self.startIndex, offsetBy: self.characters.count / 2)
		var tailIndex = frontIndex
		
		var result = self
		
		#if os(OSX)
			var size = self.size(withAttributes: atts)
		#else
			var size = (self as NSString).size(attributes: atts)
		#endif
		
		while size.width > width {
			frontIndex = self.characters.index(before: frontIndex)
			tailIndex = self.characters.index(after: tailIndex)
			
			front = self.substring(to: frontIndex)
			tail = self.substring(from: tailIndex)
			result = "\(front)...\(tail)"
			
			#if os(OSX)
				size = result.size(withAttributes: atts)
			#else
				size = (result as NSString).size(attributes: atts)
			#endif
		}
		return result
	}
	
	public mutating func prepend(_ string: String) {
		self.insert(contentsOf: string.characters, at: self.startIndex)
	}
	
	/// Returns a reverse string.
	public func reversed() -> String {
		return String(self.characters.reversed())
	}
	
	/// Returns second character, or \0 is the string has only one character (or
	/// is empty).
	public var secondCharacter: Character {
		if self.characters.count < 2 {
			return Character(UInt8(0))
		}
		
		return self.characters[self.characters.index(self.startIndex, offsetBy: 1)]
	}
	
	#if os(iOS)
	/// Apparantly, this is missing in Swift 3 on iOS.
	public func size(withAttributes attrs: [String : AnyObject]?) -> CGSize {
		return (self as NSString).size(attributes: attrs)
	}
	#endif
	
	/// Returns size with attributes, limited to width.
	public func size(withAttributes attrs: [String : AnyObject], maximumWidth width: CGFloat) -> CGSize {
		let constraintSize = CGSize(width: width, height: CGFloat.greatestFiniteMagnitude)
		#if os(iOS)
			return self.boundingRect(with: constraintSize, options: .usesLineFragmentOrigin, attributes: attrs, context: nil).size
		#else
			return self.boundingRect(with: constraintSize, options: .usesLineFragmentOrigin, attributes: attrs).size
		#endif
	}

	/// Capitalizes the first letter of the string.
	public var capitalizingFirstLetter: String {
		if self.characters.count == 0 {
			return self
		}

		let index = self.characters.index(self.startIndex, offsetBy: 1)
		let firstLetter = self.substring(to: index)
		let restOfString = self.substring(from: index)
		return firstLetter.uppercased() + restOfString
	}

	public var deletingLastCharacter: String {
		if self.isEmpty {
			fatalError("Cannot delete last character from an empty string!")
		}

		return self.substring(to: self.characters.index(before: self.endIndex))
	}

	/// Removes the prefix from the string.
	public func deleting(prefix: String) -> String {
		if !self.hasPrefix(prefix) {
			return self
		}

		return self.substring(from: self.characters.index(self.startIndex, offsetBy: prefix.characters.count))
	}

	/// Removes the suffix from the string.
	public func deleting(suffix: String) -> String {
		if !self.hasSuffix(suffix) {
			return self
		}

		let len = suffix.characters.count
		return self.substring(to: self.characters.index(self.endIndex, offsetBy: -len))
	}

	/// Encodes string by adding percent escapes. Unlike
	/// stringByAddingPercentEncodingWithAllowedCharacters(...), this never
	/// returns nil, but instead falls back to self.
	public var encodingIllegalURLCharacters: String {
		return self.addingPercentEncoding(withAllowedCharacters: CharacterSet.alphanumerics) ?? self
	}

	/// Lowercases the first letter of the string.
	public var lowercasingFirstLetter: String {
		if self.characters.count == 0 {
			return self
		}

		let index = self.characters.index(self.startIndex, offsetBy: 1)
		let firstLetter = self.substring(to: index)
		let restOfString = self.substring(from: index)
		return firstLetter.lowercased() + restOfString
	}

	/// Trims the string to maximum length of maxLen, trimming the middle.
	public func truncatingMiddle(toMaximumLengthOf maxLen: Int) -> String {
		if self.characters.count < maxLen {
			return self
		}

		let begin = self.substring(to: self.characters.index(self.startIndex, offsetBy: (maxLen - 1) / 2))
		let end = self.substring(from: self.characters.index(self.endIndex, offsetBy: -1 * (maxLen - 1) / 2))
		return begin + "…" + end
	}

	/// Prepends prefix enough times so that it has the specific length.
	public func paddingFront(toLength length: Int, withString padString: String) -> String {
		var str = self
		while str.characters.count + padString.characters.count <= length {
			str = padString + str
		}
		return str
	}
	
	/// Returns the suffix of length. Doesn't do any range checking.
	public func suffix(ofLength length: Int) -> String {
		return self.substring(from: self.characters.index(self.endIndex, offsetBy: -1 * length))
	}
	
	/// Removes characters from the set from the beginning of the string.
	public func trimmingLeftCharacters(in set: CharacterSet) -> String {
		var index = 0
		while index < self.characters.count && self.characters[self.characters.index(self.startIndex, offsetBy: index)].isMember(of: set) {
			index += 1
		}
		
		return self.substring(from: self.characters.index(self.startIndex, offsetBy: index))
	}
	
	/// Removes characters from the set from the end of the string.
	public func trimmingRightCharacters(in set: CharacterSet) -> String {
		var index = self.characters.count - 1
		while index >= 0 && self.characters[self.characters.index(self.startIndex, offsetBy: index)].isMember(of: set) {
			index -= 1
		}
		
		index += 1
		
		return self.substring(to: self.characters.index(self.startIndex, offsetBy: index))
	}

	/// Trims whitespace whitespace and newlines.
	public var trimmingWhitespace: String {
		return self.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
	}
	
	/// This method decodes the string as a URL query. E.g. arg1=val1&arg2=val2
	/// will become [ "arg1": "val1", ... ]. This is the opposite of URLQueryString()
	/// method on Dictionary
	public var urlQueryDictionary: [String: String] {
		let variablePairs = self.allVariablePairs(forRegexString: "&?(?P<VARNAME>[^=]+)=(?P<VARVALUE>[^&]+)")
		var dict: [String: String] = [:]
		for (key, value) in variablePairs {
			guard let
			decodedKey = key.removingPercentEncoding,
				let decodedValue = value.removingPercentEncoding else {
					dict[key] = value
					continue
			}

			dict[decodedKey] = decodedValue
		}
		return dict
	}
	
	/// Tries several heuristics to see if the email address is valid, or even 
	/// phony.
	public func validateEmailAddress() -> XUEmailValidationFormat {
		// First see if it fits the general description
		let regex = XURegex(pattern: "^[\\w\\.-]{2,}@[\\w\\.-]{2,}\\.\\w{2,}$", andOptions: .caseless)
		if !regex.matchesString(self) {
			return .wrong
		}
		
		// It's about right, see for some obviously phony emails
		if self.hasCaseInsensitive(substring: "fuck") || self.hasCaseInsensitive(substring: "shit")
			|| self.hasCaseInsensitive(substring: "qwert") || self.hasCaseInsensitive(substring: "asdf")
			|| self.hasCaseInsensitive(substring: "mail@mail.com") || self.hasCaseInsensitive(substring: "1234") {
			return .phony
		}
		
		return .correct
	}
	
}


public extension String {
	
	@available(*, deprecated, renamed: "draw(centeredIn:withAttributes:)")
	public func drawCenteredInRect(_ rect: CGRect, withAttributes atts: [String: AnyObject]? = nil) -> CGRect {
		return self.draw(centeredIn: rect, withAttributes: atts)
	}
	
	@available(*, deprecated, renamed: "draw(rightAlignedTo:withAttributes:)")
	public func drawRightAlignedToPoint(_ point: CGPoint, withAttributes atts: [String: AnyObject]? = nil) -> CGSize {
		return self.draw(rightAlignedTo: point, withAttributes: atts)
	}
	
	@available(*, deprecated, renamed: "hasCaseInsensitive(prefix:)")
	public func hasCaseInsensitivePrefix(_ prefix: String) -> Bool {
		return self.hasCaseInsensitive(prefix: prefix)
	}
	
	@available(*, deprecated, renamed: "hasCaseInsensitive(substring:)")
	public func hasCaseInsensitiveSubstring(_ substring: String) -> Bool {
		return self.hasCaseInsensitive(substring: substring)
	}
	
	@available(*, deprecated, renamed: "hasCaseInsensitive(suffix:)")
	public func hasCaseInsensitiveSuffix(_ suffix: String) -> Bool {
		return self.hasCaseInsensitive(suffix: suffix)
	}
	
	@available(*, deprecated, renamed: "isCaseInsensitivelyEqual(to:)")
	public func isCaseInsensitivelyEqualToString(_ string: String) -> Bool {
		return self.isCaseInsensitivelyEqual(to: string)
	}
	
	@available(*, deprecated, renamed: "md5Digest")
	public var MD5Digest: String {
		return self.md5Digest
	}
	
	@available(*, deprecated, renamed: "truncatingMiddle(toFitWidth:withAttributes:)")
	public func middleTruncatedStringToFitWidth(_ width: CGFloat, withAttributes atts: [String: AnyObject]) -> String {
		return self.truncatingMiddle(toFitWidth: width, withAttributes: atts)
	}
	
	@available(*, deprecated, renamed: "reversed()")
	public var reverseString: String {
		return self.reversed()
	}
	
	@available(*, deprecated, renamed: "size(withAttributes:maximumWidth:)")
	public func sizeWithAttributes(_ attrs: [String : AnyObject], maxWidth width: CGFloat) -> CGSize {
		return self.size(withAttributes: attrs, maximumWidth: width)
	}
	
	@available(*, deprecated, renamed: "capitalizingFirstLetter")
	public var stringByCapitalizingFirstLetter: String {
		return self.capitalizingFirstLetter
	}
	
	@available(*, deprecated, renamed: "deletingLastCharacter")
	public var stringByDeletingLastCharacter: String {
		return self.deletingLastCharacter
	}
	
	@available(*, deprecated, renamed: "deleting(prefix:)")
	public func stringByDeletingPrefix(_ prefix: String) -> String {
		return self.deleting(prefix: prefix)
	}
	
	@available(*, deprecated, renamed: "deleting(suffix:)")
	public func stringByDeletingSuffix(_ suffix: String) -> String {
		return self.deleting(suffix: suffix)
	}
	
	@available(*, deprecated, renamed: "encodingIllegalURLCharacters")
	public var stringByEncodingIllegalURLCharacters: String {
		return self.encodingIllegalURLCharacters
	}
	
	@available(*, deprecated, renamed: "lowercasingFirstLetter")
	public var stringByLowercasingFirstLetter: String {
		return self.lowercasingFirstLetter
	}

	@available(*, deprecated, renamed: "truncatingMiddle(toMaximumLengthOf:)")
	public func stringByMiddleTrimmingToMaximumLengthOf(_ maxLen: Int) -> String {
		return self.truncatingMiddle(toMaximumLengthOf: maxLen)
	}
	
	@available(*, deprecated, renamed: "paddingFront(toLength:withString:)")
	public func stringByPaddingFrontToLength(_ length: Int, withString padString: String) -> String {
		return self.paddingFront(toLength: length, withString: padString)
	}
	
	@available(*, deprecated, renamed: "trimmingLeftCharacters(in:)")
	public func stringByTrimmingLeftCharactersInSet(_ set: CharacterSet) -> String {
		return self.trimmingLeftCharacters(in: set)
	}
	
	@available(*, deprecated, renamed: "trimmingRightCharacters(in:)")
	public func stringByTrimmingRightCharactersInSet(_ set: CharacterSet) -> String {
		return self.trimmingRightCharacters(in: set)
	}
	
	@available(*, deprecated, renamed: "trimmingWhitespace")
	public var stringByTrimmingWhitespace: String {
		return self.trimmingWhitespace
	}
	
	@available(*, deprecated, renamed: "suffix(ofLength:)")
	public func suffixOfLength(_ length: Int) -> String {
		return self.suffix(ofLength: length)
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

		let charSet = CharacterSet(charactersIn: "0123456789.")
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

			if char.isMember(of: charSet) {
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

		let charSet = CharacterSet(charactersIn: "0123456789")
		var numberString = ""
		for char in self.characters {
			if char.isMember(of: charSet) {
				numberString.append(char)
			} else {
				break
			}
		}

		return Int(numberString) ?? 0
	}
}
