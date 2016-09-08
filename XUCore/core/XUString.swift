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

public func +=(lhs: inout XUString, rhs: XUString) {
	lhs = lhs.stringByAppendingString(rhs)
}

public func +=(lhs: inout XUString, rhs: String) {
	lhs = lhs.stringByAppendingString(XUString(string: rhs))
}

public func +=(lhs: XUString, rhs: XUString.XUChar) {
	lhs.appendCharacter(rhs)
}

public extension Sequence where Iterator.Element == XUString {
	
	/// Interpose the `separator` between elements of `self`, then concatenate
	/// the result.  For example:
	///
	///     ["foo", "bar", "baz"].joinWithSeparator("-|-") // "foo-|-bar-|-baz"
	
	public func joinWithSeparator(_ separator: XUString) -> XUString {
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
open class XUString: Equatable, CustomDebugStringConvertible, CustomStringConvertible {
	
	/// A typealias for the char. We're using UInt8.
	public typealias XUChar = UInt8
	
	fileprivate var _buffer: [XUChar]
	
	
	/// Appends a character at the end of the buffer.
	open func appendCharacter(_ char: XUChar) {
		_buffer.append(char)
	}
	
	/// Returns character at index.
	open func characterAtIndex(_ index: Int) -> XUChar {
		return _buffer[index]
	}
	
	/// Returns the inner string buffer. Should not be accessed, unless you have
	/// a good reason for it..
	open var characters: [XUChar] {
		return _buffer
	}
	
	/// Returns a copy of self.
	open func copy() -> XUString {
		return XUString(chars: _buffer)
	}
	
	/// Returns bytes wrapped in NSData.
	open var data: Data {
		return Data(bytes: _buffer)
	}
	
	open var debugDescription: String {
		return self.description
	}
	
	open var description: String {
		return "XUString<\(Unmanaged.passUnretained(self).toOpaque())> [length: \(self.length)] - \(self.stringValue)"
	}
	
	open func hasPrefix(_ prefix: XUString) -> Bool {
		if prefix.length > self.length {
			return false
		}
		
		for i in 0 ..< prefix.length {
			if prefix[i] != self[i] {
				return false
			}
		}
		
		return true
	}
	
	/// Returns an index of the first occurrence of the char.
	open func indexOfCharacter(_ char: XUChar) -> Int? {
		return _buffer.index(of: char)
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
	@available(*, deprecated, message: "Use init(chars:) instead.")
	public convenience init(characterCodes: [NSNumber]) {
		let chars = characterCodes.map({ $0.uint8Value })
		self.init(chars: chars)
	}
	
	/// Interprets NSData as a const char *
	public convenience init(dataBytes data: Data) {
		let count = data.count
		
		var chars = Array<XUChar>(repeating: 0, count: count)
		(data as NSData).getBytes(&chars, length: count)
		
		self.init(chars: chars)
	}
	
	/// Convenience method that fills the string with str[0] = 0, str[1] = 1, ...
	public convenience init(filledWithASCIITableOfLength length: Int) {
		var chars: [XUChar] = [ ]
		for i in 0 ..< length {
			chars.append(XUChar(i))
		}
		
		self.init(chars: chars)
	}
	
	/// Convenience method that fills the string with c.
	public convenience init(filledWithChar c: XUChar, ofLength length: Int) {
		let chars = Array<XUChar>(repeating: c, count: length)
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
	
	open var lastCharacter: XUChar {
		assert(self.length > 0)
		
		return self.characterAtIndex(self.length - 1)
	}
	
	/// Returns the length of the string.
	open var length: Int {
		return _buffer.count
	}
	
	/// Returns MD5 digest of the data.
	open var MD5Digest: String {
		return self.data.MD5Digest
	}
	
	/// Removes character at index by shifting the remainder of the string left.
	open func removeCharacterAtIndex(_ index: Int) {
		_buffer.remove(at: index)
	}
	
	/// Removes characters in range by shifting the remainder of the string left.
	open func removeCharactersInRange(_ range: Range<Int>) {
		_buffer.removeSubrange(range)
	}
	
	/// Removes all characters passing the filter.
	open func removeCharactersPassingTest(_ test: (_ character: XUChar, _ index: Int) -> Bool) {
		for i in (0..<_buffer.count).reversed() {
			if test(_buffer[i], i) {
				_buffer.remove(at: i)
			}
		}
	}
	
	/// Removes last character.
	open func removeLastCharacter() {
		assert(self.length > 0)
		
		self.removeCharacterAtIndex(self.length - 1)
	}
	
	/// Removes all characters with value > 127
	open func removeNonASCIICharacters() {
		self.removeCharactersPassingTest({ $0.0 > 127 })
	}
	
	/// Sets a character at index. Will throw if the index is out of bounds.
	open func setCharacter(_ char: XUChar, atIndex index: Int) {
		_buffer[index] = char
	}
	
	/// Returns a string by appending another string.
	open func stringByAppendingString(_ string: XUString) -> XUString {
		return XUString(chars: _buffer + string._buffer)
	}
	
	/// Returns the inner string buffer. Should not be accessed.
	@available(*, unavailable, renamed: "characters")
	open var string: [XUChar] {
		return _buffer
	}
	
	/// Returns a constructed string from the chars.
	open var stringValue: String {
		var value = ""
		for c in _buffer {
			value.append(String(describing: UnicodeScalar(UInt32(c))))
		}
		return value
	}
	
	/// Returns a string containing everything after index.
	open func substringFromIndex(_ index: Int) -> XUString {
		return self.substringWithRange(index..<self.length)
	}
	
	/// Returns a string containing `length` first characters.
	open func substringToIndex(_ index: Int) -> XUString {
		return self.substringWithRange(0..<index)
	}
	
	/// Returns a substring in range.
	open func substringWithRange(_ range: Range<Int>) -> XUString {
		let slice = _buffer[range]
		return XUString(chars: Array<XUChar>(slice))
	}
	
	/// Swaps the two characters.
	open func swapCharacterAtIndex(_ index1: Int, withCharacterAtIndex index2: Int) {
		let c1 = _buffer[index1]
		let c2 = _buffer[index2]
		
		_buffer[index1] = c2
		_buffer[index2] = c1
	}

	
	open subscript(index: Int) -> XUChar {
		get {
			return self.characterAtIndex(index)
		}
		set {
			self.setCharacter(newValue, atIndex: index)
		}
	}
	
}

/// Allow iteration of the string.
extension XUString: Sequence {
	
	public typealias Iterator = XUStringGenerator
	
	public func makeIterator() -> XUStringGenerator {
		return XUStringGenerator(string: self)
	}
	
}

/// Generator for XUString.
open class XUStringGenerator: IteratorProtocol {
	
	public typealias Element = XUString.XUChar
	
	/// Current index we're at.
	open var currentIndex: Int
	
	/// The string we're iterating.
	open let string: XUString
	
	/// Returns next element.
	open func next() -> XUString.XUChar? {
		if currentIndex + 1 >= self.string.length {
			return nil
		}
		
		self.currentIndex += 1
		return self.string[self.currentIndex]
	}
	
	/// Initializes with a string.
	public init(string: XUString) {
		self.string = string
		self.currentIndex = 0
	}
	
}

