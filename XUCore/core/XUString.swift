//
//  XUString.swift
//  XUCore
//
//  Created by Charlie Monroe on 11/26/15.
//  Copyright © 2015 Charlie Monroe Software. All rights reserved.
//

import Foundation

public func ==(lhs: XUString, rhs: XUString) -> Bool {
	return lhs._buffer == rhs._buffer
}

public func +=(inout lhs: XUString, rhs: XUString) {
	lhs = lhs.stringByAppendingString(rhs)
}

public func +=(inout lhs: XUString, rhs: String) {
	lhs = lhs.stringByAppendingString(XUString(string: rhs))
}

public func +=(lhs: XUString, rhs: XUString.XUChar) {
	lhs.appendCharacter(rhs)
}

public extension SequenceType where Generator.Element == XUString {
	
	/// Interpose the `separator` between elements of `self`, then concatenate
	/// the result.  For example:
	///
	///     ["foo", "bar", "baz"].joinWithSeparator("-|-") // "foo-|-bar-|-baz"
	@warn_unused_result
	public func joinWithSeparator(separator: XUString) -> XUString {
		var result = XUString()
		var previous: XUString? = nil
		for item in self {
			if previous != nil {
				result = result.stringByAppendingString(separator)
			}
			result = result.stringByAppendingString(item)
			previous = item
		}
		return result
	}
	
}



/// This is a class that helps dealing with various string computations by
/// allowing direct modification of characters in the string. The string is just
/// a byte array, hence can be used even for data.
public class XUString: Equatable, CustomDebugStringConvertible, CustomStringConvertible {
	
	/// A typealias for the char. We're using UInt8.
	public typealias XUChar = UInt8
	
	private var _buffer: [XUChar]
	
	
	/// Appends a character at the end of the buffer.
	public func appendCharacter(char: XUChar) {
		_buffer.append(char)
	}
	
	/// Returns character at index.
	public func characterAtIndex(index: Int) -> XUChar {
		return _buffer[index]
	}
	
	/// Returns bytes wrapped in NSData.
	public var data: NSData {
		return NSData(bytes: &_buffer, length: _buffer.count)
	}
	
	public var debugDescription: String {
		return self.description
	}
	
	public var description: String {
		return "XUString<\(unsafeAddressOf(self))> [length: \(self.length)] - \(self.stringValue)"
	}
	
	/// Returns an index of the first occurrence of the char.
	public func indexOfCharacter(char: XUChar) -> Int? {
		return _buffer.indexOf(char)
	}
	
	/// Designated initializer.
	public init(chars: [XUChar]) {
		_buffer = chars
	}

	/// Creates an empty string.
	public convenience init() {
		self.init(chars: [ ])
	}
	
	/// Takes an array of NSNumber's which represent individual chars.
	@available(*, deprecated, message="Use init(chars:) instead.")
	public convenience init(characterCodes: [NSNumber]) {
		let chars = characterCodes.map({ $0.unsignedCharValue })
		self.init(chars: chars)
	}
	
	/// Interprets NSData as a const char *
	public convenience init(dataBytes data: NSData) {
		let count = data.length
		
		var chars = Array<XUChar>(count: count, repeatedValue: 0)
		data.getBytes(&chars, length: count)
		
		self.init(chars: chars)
	}
	
	/// Convenience method that fills the string with str[0] = 0, str[1] = 1, ...
	public convenience init(filledWithASCIITableOfLength length: UInt) {
		var chars: [XUChar] = [ ]
		for i in 0..<Int(length) {
			chars.append(XUChar(i))
		}
		
		self.init(chars: chars)
	}
	
	/// Convenience method that fills the string with c.
	public convenience init(filledWithChar c: XUChar, ofLength length: Int) {
		let chars = Array<XUChar>(count: length, repeatedValue: c)
		self.init(chars: chars)
	}
	
	/// Inits with a string.
	public convenience init(string: String) {
		var chars: [XUChar] = [ ]
		for x in string.utf8 {
			chars.append(x)
		}
		self.init(chars: chars)
	}
	
	public var lastCharacter: XUChar {
		assert(self.length > 0)
		
		return self.characterAtIndex(self.length - 1)
	}
	
	/// Returns the length of the string.
	public var length: Int {
		return _buffer.count
	}
	
	/// Returns MD5 digest of the data.
	public var MD5Digest: String {
		return self.data.MD5Digest
	}
	
	/// Removes character at index by shifting the remainder of the string left.
	public func removeCharacterAtIndex(index: Int) {
		_buffer.removeAtIndex(index)
	}
	
	/// Removes all characters passing the filter.
	public func removeCharactersPassingTest(test: (character: XUChar, index: Int) -> Bool) {
		for i in (0..<_buffer.count).reverse() {
			if test(character: _buffer[i], index: i) {
				_buffer.removeAtIndex(i)
			}
		}
	}
	
	/// Removes last character.
	public func removeLastCharacter() {
		assert(self.length > 0)
		
		self.removeCharacterAtIndex(self.length - 1)
	}
	
	/// Removes all characters with value > 127
	public func removeNonASCIICharacters() {
		self.removeCharactersPassingTest({ $0.character > 127 })
	}
	
	/// Sets a character at index. Will throw if the index is out of bounds.
	public func setCharacter(char: XUChar, atIndex index: Int) {
		_buffer[index] = char
	}
	
	/// Returns a string by appending another string.
	public func stringByAppendingString(string: XUString) -> XUString {
		return XUString(chars: _buffer + string._buffer)
	}
	
	/// Returns the inner string buffer. Should not be accessed.
	public var string: [XUChar] {
		return _buffer
	}
	
	/// Returns a constructed string from the chars.
	public var stringValue: String {
		var value = ""
		for c in _buffer {
			value.append(UnicodeScalar(UInt32(c)))
		}
		return value
	}
	
	/// Returns a string containing everything after index.
	public func substringFromIndex(index: Int) -> XUString {
		return self.substringWithRange(index..<self.length)
	}
	
	/// Returns a string containing `length` first characters.
	public func substringToIndex(index: Int) -> XUString {
		return self.substringWithRange(0..<index)
	}
	
	/// Returns a substring in range.
	public func substringWithRange(range: Range<Int>) -> XUString {
		let slice = _buffer[range]
		return XUString(chars: Array<XUChar>(slice))
	}
	
	/// Swaps the two characters.
	public func swapCharacterAtIndex(index1: Int, withCharacterAtIndex index2: Int) {
		let c1 = _buffer[index1]
		let c2 = _buffer[index2]
		
		_buffer[index1] = c2
		_buffer[index2] = c1
	}

	
	public subscript(index: Int) -> XUChar {
		return self.characterAtIndex(index)
	}
	
	
}
