//
//  StringExtensions.swift
//  DownieCore
//
//  Created by Charlie Monroe on 8/6/15.
//  Copyright © 2015 Charlie Monroe Software. All rights reserved.
//

import Foundation

/// + operator for String + Character
public func + (lhs: String, rhs: Character) -> String {
	return lhs + String(rhs)
}

/// += operator for String + Character
public func += (lhs: inout String, rhs: Character) {
	lhs = lhs + String(rhs)
}


public enum XUEmailFormatValidity {
	
	/// Correct format.
	case correct
	
	/// Wrong. Missing @ sign, etc.
	case wrong
	
	/// Phony. E.g. a@a.com.
	case phony
	
	public init(email: String) {
		// First see if it fits the general description
		let regex = XURegex(pattern: "^[\\w\\.\\-_+]{1,}@[\\w\\.-]{2,}\\.\\w{2,}$", andOptions: .caseless)
		if !regex.matchesString(email) {
			self = .wrong
			return
		}
		
		// It's about right, see for some obviously phony emails
		let matches = [
			"fuck", "shit", "qwert", "asdf", "mail@mail.com", "annoying@problem.com",
			"noname@nothing.com", "example.com", "sdsbgt@gmail.com", "me@you.com", "none@none.com",
			"tembo@mac.com", "any@hotmail.com", "nowhere.us", "www@gmail.com", "john@mac.com",
			"dasdsad", "noreply", "@abc.com", "123@123.com", "anon@anon.com", "no@no.com"
		]
		
		if matches.contains(where: email.contains(caseInsensitive:)) {
			self = .phony
			return
		}
		
		let regexMatchs = [
			"^1+@(1+|qq|16\\d)\\.com$",
			"^test@\\w+\\.com$",
			"^1234@",
			"^test@gmail.com"
		]
		if regexMatchs.contains(where: { email.matches(regex: $0) }) {
			self = .phony
			return
		}
		
		self = .correct
	}
	
}

extension String.Encoding {
	
	/// Init with CFStringEncodings.
	public init(encoding: CFStringEncodings) {
		self.init(rawValue: CFStringConvertEncodingToNSStringEncoding(CFStringEncoding(encoding.rawValue)))
	}
	
}

extension StringProtocol {
	
	/// Returns hexValue of the string.
	public var hexValue: Int {
		// We support e.g. "0xFF"
		let suffix = self.drop(while: { $0 == Character("0") || $0 == Character("x") || $0 == Character("X") })
		var result = 0
		for c in suffix {
			guard let ascii = c.asciiValue else {
				break
			}
			
			if c >= Character("0") && c <= Character("9") {
				result *= 16
				result += Int(ascii - Character("0").asciiValue!)
			} else if c >= Character("a") && c <= Character("f") {
				result *= 16
				result += Int(ascii - Character("a").asciiValue!) + 10
			} else if c >= Character("A") && c <= Character("F") {
				result *= 16
				result += Int(ascii - Character("A").asciiValue!) + 10
			} else {
				break
			}
		}
		return result
	}
	
}


extension String {
	
	
	/// Decodes `self` as base64-encoded `NSData` and tries to create a string
	/// from the result.
	public var base64DecodedString: String? {
		guard let data = Data(base64Encoded: self, options: .ignoreUnknownCharacters) else {
			return nil
		}
		
		return String(data: data)
	}

	/// Returns true if the receiver has `substring` in case-insensitive
	/// comparison.
	public func contains(caseInsensitive substring: String) -> Bool {
		return self.range(of: substring, options: .caseInsensitive) != nil
	}
	
	/// Returns true if the receiver contains a unicode scalar from the character
	/// set.
	public func containsCharacter(from charSet: CharacterSet) -> Bool {
		return self.unicodeScalars.contains(where: { charSet.contains($0) })
	}
	
	/// Ensures that the string has a prefix. If the string already has a prefix,
	/// `self` is returned, otherwise `prefix + self`.
	public func ensuring(prefix: String) -> String {
		if self.hasPrefix(prefix) {
			return self
		}
		return prefix + self
	}
	
	/// Ensures that the string has a suffix. If the string already has a suffix,
	/// `self` is returned, otherwise `self + suffix`.
	public func ensuring(suffix: String) -> String {
		if self.hasSuffix(suffix) {
			return self
		}
		return self + suffix
	}

	/// This converts string to UInt as a fourCharCode
	public var fourCharCodeValue: Int {
		var result: Int = 0
		if let data = self.data(using: .macOSRoman) {
			data.withUnsafeBytes { rawBytes in
				let bytes = rawBytes.bindMemory(to: UInt8.self)
				for i in 0 ..< data.count {
					result = result << 8 + Int(bytes[i])
				}
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

	/// Returns true if the receiver has prefix `suffix` in case-insensitive
	/// comparison.
	public func hasCaseInsensitive(suffix: String) -> Bool {
		guard let range = self.range(of: suffix, options: .caseInsensitive) else {
			return false
		}

		return range.upperBound == self.endIndex
	}

	/// Replaces & -> &amp; etc. Unlike htmlUnescapedString, this is not fully
	/// implemented and will pretty much just substitute several major entities:
	/// &, ", ', <, >.
	public var htmlEscapedString: String {
		var string = self
		string = string.replacingOccurrences(of: "&", with: "&amp;", options: .literal)
		string = string.replacingOccurrences(of: "\"", with: "&quot;", options: .literal)
		string = string.replacingOccurrences(of: "'", with: "&#x27;", options: .literal)
		string = string.replacingOccurrences(of: ">", with: "&gt;", options: .literal)
		string = string.replacingOccurrences(of: "<", with: "&lt;", options: .literal)
		
		return string
	}

	/// Replaces &amp; -> & etc. Unlike htmlEscapedString, this is implemented to
	/// greated extent. It will replace some known entities (&nbsp;, &quot;, ...)
	/// but it will also find occurrences of entities such as &#32;, etc.
	public var htmlUnescapedString: String {
		var string = self
		for (entity, replacement) in htmlEntityNameMapping {
			string = string.replacingOccurrences(of: entity, with: replacement, options: .literal)
		}

		let hexRegex = XURegex(pattern: "&#(?P<C>x?[0-9a-f]+);", andOptions: .caseless)
		for occurrence in self.allValues(of: "C", forRegex: hexRegex).distinct() {
			let value: Int
			if occurrence.hasPrefix("x") {
				// Hex
				value = occurrence.deleting(prefix: "x").hexValue
			} else {
				value = occurrence.integerValue
			}
			
			guard let replacement = UnicodeScalar(value).flatMap({ String(Character($0)) }) else {
				continue
			}
			
			string = string.replacingOccurrences(of: "&#\(occurrence);", with: replacement)
		}
		
		let accentedCharacterMapping: [(htmlName: String, combiningUnicodeSequence: String)] = [
			("acute", "\u{0341}"), ("caron", "\u{030C}"), ("grave", "\u{0302}"),
			("dot", "\u{0307}"), ("uml", "\u{0308}"), ("tilde", "\u{0303}"),
			("slash", "\u{0337}"), ("circ", "\u{0302}"), ("ring", "\u{030A}"),
			("breve", "\u{0306}"), ("macr", "\u{0304}"), ("ogon", "\u{0328}")
		]

		for (htmlName, combiningUnicodeSequence) in accentedCharacterMapping {
			let accentRegex = XURegex(pattern: "&(?P<C>[a-zA-Z])\(htmlName);", andOptions: [])
			for occurrence in self.allValues(of: "C", forRegex: accentRegex).distinct() {
				string = string.replacingOccurrences(of: "&\(occurrence)\(htmlName);", with: occurrence + combiningUnicodeSequence)
			}
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
	public init?(data: Data) {
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

	/// This method takes the string and replaces \r, \n, \t, \u3245, etc. with
	/// proper characters. This encoding is mostly in JSON and JavaScript.
	public var jsonDecodedString: String {
		var result = self
		result = result.replacingOccurrences(of: "\\r", with: String(Character(UnicodeScalar(13))))
		result = result.replacingOccurrences(of: "\\n", with: String(Character(UnicodeScalar(10))))
		result = result.replacingOccurrences(of: "\\t", with: String(Character(UnicodeScalar(9))))

		var i: String.Index = self.startIndex
		while i < self.endIndex {
			let c = self[i]
			if c == Character("\\") && i < self.index(self.endIndex, offsetBy: -1) {
				let nextC = self[self.index(after: i)]
				if nextC == Character("u") && i < self.index(self.endIndex, offsetBy: -6) {
					let unicodeCharCode = self[self.index(i, offsetBy: 2) ..< self.index(i, offsetBy: 6)]
					let replacementChar = String(unicodeCharCode).hexValue
					
					result = result.replacingOccurrences(of: "\\u\(unicodeCharCode)", with: String(Character(UnicodeScalar(replacementChar)!)))
					i = self.index(i, offsetBy: 6)
					continue
				}
			}
			
			i = self.index(after: i)
		}
		return result
	}
	
	/// Splits `self` using CharacterSet.newlines.
	public var lines: [String] {
		return self.components(separatedBy: CharacterSet.newlines)
	}

	/// Computes MD5 digest of self. Will call fatalError if the string can't be
	/// represented in UTF8.
	public var md5Digest: String {
		guard let data = self.data(using: String.Encoding.utf8) else {
			fatalError("Can't represent string as UTF8 - \(self).")
		}
		
		return data.md5Digest.hexEncodedString
	}
	
	/// Returns self as octal value - i.e. interpret the number as in octal
	/// representation.
	public var octalValue: Int {
		var result = 0
		for c in self {
			if c >= Character("0") && c <= Character("8") {
				result *= 8
				result += Int(c.asciiValue! - Character("0").asciiValue!)
			} else {
				break
			}
		}
		return result
	}
	
	/// Prepends self with `string`.
	public mutating func prepend(with string: String) {
		self.insert(contentsOf: string, at: self.startIndex)
	}
	
	/// Capitalizes the first letter of the string.
	public var capitalizingFirstLetter: String {
		if self.isEmpty {
			return self
		}
		
		let index = self.index(self.startIndex, offsetBy: 1)
		let firstLetter = self[..<index]
		let restOfString = self[index...]
		return firstLetter.uppercased() + restOfString
	}

	/// Returns a string with the last character removed. Will trap in case
	/// the string is empty.
	public func deletingLastCharacter() -> String {
		if self.isEmpty {
			XUFatalError("Cannot delete last character from an empty string!")
		}

		return String(self[..<self.index(before: self.endIndex)])
	}

	/// Removes the prefix from the string.
	public func deleting(prefix: String) -> String {
		if !self.hasPrefix(prefix) {
			return self
		}

		return String(self[self.index(self.startIndex, offsetBy: prefix.count)...])
	}

	/// Removes the suffix from the string.
	public func deleting(suffix: String) -> String {
		if !self.hasSuffix(suffix) {
			return self
		}

		let len = suffix.count
		return String(self[..<self.index(self.endIndex, offsetBy: -len)])
	}

	/// Encodes string by adding percent escapes. Unlike
	/// stringByAddingPercentEncodingWithAllowedCharacters(...), this never
	/// returns nil, but instead falls back to self.
	public var encodingIllegalURLCharacters: String {
		var characterSet = CharacterSet.urlPathAllowed
		characterSet.formUnion(CharacterSet.urlQueryAllowed)
		characterSet.remove(charactersIn: "/:&+") // We need / to become %2F
		
		return self.addingPercentEncoding(withAllowedCharacters: characterSet) ?? self
	}

	/// Lowercases the first letter of the string.
	public var lowercasingFirstLetter: String {
		if self.isEmpty {
			return self
		}

		let index = self.index(self.startIndex, offsetBy: 1)
		let firstLetter = self[..<index]
		let restOfString = self[index...]
		return firstLetter.lowercased() + restOfString
	}

	/// Trims the string to maximum length of maxLen, trimming the middle.
	public func truncatingMiddle(toMaximumLengthOf maxLen: Int) -> String {
		if self.count < maxLen {
			return self
		}

		let begin = self[..<self.index(self.startIndex, offsetBy: (maxLen - 1) / 2)]
		let end = self[self.index(self.endIndex, offsetBy: -1 * (maxLen - 1) / 2)...]
		return String(begin + "…" + end)
	}

	/// Prepends prefix enough times so that it has the specific length.
	public func paddingFront(toLength length: Int, withString padString: String) -> String {
		var str = self
		while str.count + padString.count <= length {
			str = padString + str
		}
		return str
	}
	
	/// Returns the prefix of length. Doesn't do any range checking.
	public func prefix(ofLength length: Int) -> String {
		return String(self[..<self.index(self.startIndex, offsetBy: length)])
	}
	
	/// Returns the suffix of length. Doesn't do any range checking.
	public func suffix(ofLength length: Int) -> String {
		return String(self[self.index(self.endIndex, offsetBy: -1 * length)...])
	}
	
	/// Removes characters from the set from the beginning of the string.
	public func trimmingLeftCharacters(in set: CharacterSet) -> String {
		var index = 0
		while index < self.count && self[self.index(self.startIndex, offsetBy: index)].isMember(of: set) {
			index += 1
		}
		
		return String(self[self.index(self.startIndex, offsetBy: index)...])
	}
	
	/// Removes characters from the set from the end of the string.
	public func trimmingRightCharacters(in set: CharacterSet) -> String {
		var index = self.count - 1
		while index >= 0 && self[self.index(self.startIndex, offsetBy: index)].isMember(of: set) {
			index -= 1
		}
		
		index += 1
		
		return String(self[..<self.index(self.startIndex, offsetBy: index)])
	}

	/// Trims whitespace whitespace and newlines.
	public var trimmingWhitespace: String {
		return self.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
	}
	
	private static let urlQueryDictionaryRegex: XURegex = XURegex(pattern: "&?(?P<VARNAME>[^=]+)=(?P<VARVALUE>[^&]+|)(&|$)", andOptions: .caseless)
	
	/// This method decodes the string as a URL query. E.g. arg1=val1&arg2=val2
	/// will become [ "arg1": "val1", ... ]. This is the opposite of URLQueryString()
	/// method on Dictionary
	public var urlQueryDictionary: [String : String] {
		let variablePairs = self.allVariablePairs(forRegex: Self.urlQueryDictionaryRegex)
		var dict: [String: String] = [:]
		for (key, value) in variablePairs {
			guard
				let decodedKey = key.removingPercentEncoding,
				let decodedValue = value.removingPercentEncoding
			else {
				dict[key] = value
				continue
			}

			dict[decodedKey] = decodedValue
		}
		return dict
	}
	
	/// Returns Data containing UTF8 representation of this string. Unlike
	/// the failable .data(using:), this will always return nonnil value since
	/// it's using self.utf8CString which is not nullable. You are hence encouraged
	/// to use this property instead of .data(using: .utf8).
	public var utf8Data: Data {
		return self.utf8CString.withUnsafeBufferPointer { (ptr) -> Data in
			/// It includes the terminating 0 - we need to remove it.
			return Data(buffer: ptr).trimmingTrailingZeros
		}
	}
	
	/// Wraps the string so that each line has maximum length of `length`. For 
	/// example "hello" wrapped to max length of 2 is "he\nll\no".
	public func wrapped(to lineWidth: Int) -> String {
		let lineCharacters = self.lines.map({
			Array($0).splitIntoChunks(ofSize: lineWidth)
		}).joined()
		
		let lines = lineCharacters.map({ String($0) })
		return lines.joined(separator: "\n")
	}
		
}

/// Numeric methods
extension String {

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
		for char in self {
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
		for char in self {
			if char.isMember(of: charSet) {
				numberString.append(char)
			} else {
				break
			}
		}

		return Int(numberString) ?? 0
	}
}
