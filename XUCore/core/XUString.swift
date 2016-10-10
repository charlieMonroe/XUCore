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
	lhs = lhs.appending(rhs)
}

public func +=(lhs: inout XUString, rhs: String) {
	lhs = lhs.appending(XUString(string: rhs))
}

public func +=(lhs: XUString, rhs: XUString.XUChar) {
	lhs.append(rhs)
}

public extension Sequence where Iterator.Element == XUString {
	
	/// Interpose the `separator` between elements of `self`, then concatenate
	/// the result.  For example:
	///
	///     ["foo", "bar", "baz"].joinWithSeparator("-|-") // "foo-|-bar-|-baz"
	public func joined(separator: XUString = XUString()) -> XUString {
		var result = XUString()
		var previous: XUString? = nil
		for item in self {
			if previous != nil && !separator.isEmpty {
				result = result.appending(separator)
			}
			result = result.appending(item)
			previous = item
		}
		return result
	}
	
}

public extension XUString {
	
	@available(*, deprecated, renamed: "append")
	public func appendCharacter(_ char: Character) {
		self.append(char)
	}
	
	@available(*, deprecated, renamed: "character(at:)")
	public func characterAtIndex(_ index: Int) -> Character {
		return self.character(at: index)
	}
	
	@available(*, deprecated, renamed: "index(of:)")
	public func indexOfCharacter(_ char: XUChar) -> Int? {
		return self.index(of: char)
	}
	
	@available(*, deprecated, renamed: "remove(at:)")
	public func removeCharacterAtIndex(_ index: Int) {
		self.remove(at: index)
	}
	
	@available(*, deprecated, renamed: "removeSubrange(_:)")
	public func removeCharactersInRange(_ range: Range<Int>) {
		self.removeSubrage(range)
	}
	
	@available(*, deprecated, renamed: "remove(passingTest:)")
	public func removeCharactersPassingTest(_ test: (_ character: XUChar, _ index: Int) -> Bool) {
		self.remove(passingTest: test)
	}
	
	@available(*, deprecated, renamed: "appending(_:)")
	public func stringByAppendingString(_ string: XUString) -> XUString {
		return self.appending(string)
	}
	
	@available(*, deprecated, renamed: "substring(from:)")
	public func substringFromIndex(_ index: Int) -> XUString {
		return self.substring(from: index)
	}
	
	@available(*, deprecated, renamed: "substring(to:)")
	public func substringToIndex(_ index: Int) -> XUString {
		return self.substring(to: index)
	}
	
	@available(*, deprecated, renamed: "substring(with:)")
	public func substringWithRange(_ range: Range<Int>) -> XUString {
		return self.substring(with: range)
	}
	
	@available(*, deprecated, renamed: "swap(characterAt:withCharacterAt:)")
	public func swapCharacterAtIndex(_ index1: Int, withCharacterAtIndex index2: Int) {
		self.swap(characterAt: index1, withCharacterAt: index2)
	}
	
}

/// This is a class that helps dealing with various string computations by
/// allowing direct modification of characters in the string. The string is just
/// a byte array, hence can be used even for data.
public final class XUString: Equatable, CustomDebugStringConvertible, CustomStringConvertible {
	
	/// A typealias for the char. We're using UInt8.
	public typealias Character = UInt8
	
	@available(*, deprecated, renamed: "Character")
	public typealias XUChar = UInt8
	
	fileprivate var _buffer: [Character]
	
	
	/// Appends a character at the end of the buffer.
	public func append(_ char: Character) {
		_buffer.append(char)
	}
	
	/// Returns a string by appending another string.
	public func appending(_ string: XUString) -> XUString {
		return XUString(chars: _buffer + string._buffer)
	}
	
	/// Returns character at index.
	public func character(at index: Int) -> Character {
		return _buffer[index]
	}
	
	/// Returns the inner string buffer. Should not be accessed, unless you have
	/// a good reason for it..
	public var characters: [Character] {
		return _buffer
	}
	
	/// Returns a copy of self.
	public func copy() -> XUString {
		return XUString(chars: _buffer)
	}
	
	/// Returns bytes wrapped in NSData.
	public var data: Data {
		return Data(bytes: _buffer, count: self.length)
	}
	
	public var debugDescription: String {
		return self.description
	}
	
	public var description: String {
		return "XUString<\(Unmanaged.passUnretained(self).toOpaque())> [length: \(self.length)] - \(self.stringValue)"
	}
	
	public func hasPrefix(_ prefix: XUString) -> Bool {
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
	public func index(of char: Character) -> Int? {
		return _buffer.index(of: char)
	}
	
	/// Designated initializer.
	public init(chars: [Character]) {
		_buffer = chars
	}

	/// Creates an empty string.
	public convenience init() {
		self.init(chars: [ ])
	}
	
	/// Interprets NSData as a const char *
	public convenience init(dataBytes data: Data) {
		let count = data.count
		
		var chars = Array<Character>(repeating: 0, count: count)
		data.withUnsafeBytes { (bytes: UnsafePointer<Character>) in
			for i in 0 ..< count {
				chars[i] = bytes[i]
			}
		}
		
		self.init(chars: chars)
	}
	
	/// Convenience method that fills the string with str[0] = 0, str[1] = 1, ...
	public convenience init(filledWithASCIITableOfLength length: Int) {
		var chars: [Character] = [ ]
		for i in 0 ..< length {
			chars.append(Character(i))
		}
		
		self.init(chars: chars)
	}
	
	/// Convenience method that fills the string with c.
	public convenience init(filledWithCharacter c: Character, ofLength length: Int) {
		let chars = Array<Character>(repeating: c, count: length)
		self.init(chars: chars)
	}
	
	/// Inits with a string.
	public convenience init(string: String) {
		var chars: [Character] = []
		for x in string.utf8 {
			chars.append(x)
		}
		self.init(chars: chars)
	}
	
	/// Return true iff self.length == 0.
	public var isEmpty: Bool {
		return self.length == 0
	}
	
	public var lastCharacter: Character {
		assert(self.length > 0)
		
		return self.character(at: self.length - 1)
	}
	
	/// Returns the length of the string.
	public var length: Int {
		return _buffer.count
	}
	
	/// Returns MD5 digest of the data.
	public var md5Digest: String {
		return self.data.md5Digest
	}
	
	/// Removes character at index by shifting the remainder of the string left.
	public func remove(at index: Int) {
		_buffer.remove(at: index)
	}
	
	/// Removes characters in range by shifting the remainder of the string left.
	public func removeSubrage(_ range: Range<Int>) {
		_buffer.removeSubrange(range)
	}
	
	/// Removes all characters passing the filter.
	public func remove(passingTest test: (_ character: Character, _ index: Int) -> Bool) {
		for i in (0 ..< _buffer.count).reversed() {
			if test(_buffer[i], i) {
				_buffer.remove(at: i)
			}
		}
	}
	
	/// Removes last character.
	public func removeLastCharacter() {
		assert(self.length > 0)
		
		self.remove(at: self.length - 1)
	}
	
	/// Removes all characters with value > 127
	public func removeNonASCIICharacters() {
		self.remove(passingTest: { $0.0 > 127 })
	}
	
	/// Sets a character at index. Will throw if the index is out of bounds.
	public func setCharacter(_ char: Character, atIndex index: Int) {
		_buffer[index] = char
	}
	
	/// Returns a constructed string from the chars.
	public var stringValue: String {
		var value = ""
		for c in _buffer {
			value.append(Swift.Character(c))
		}
		return value
	}
	
	/// Returns a string containing everything after index.
	public func substring(from index: Int) -> XUString {
		return self.substring(with: index ..< self.length)
	}
	
	/// Returns a string containing `length` first characters.
	public func substring(to index: Int) -> XUString {
		return self.substring(with: 0 ..< index)
	}
	
	/// Returns a substring in range.
	public func substring(with range: Range<Int>) -> XUString {
		let slice = _buffer[range]
		return XUString(chars: Array<Character>(slice))
	}
	
	/// Swaps the two characters.
	public func swap(characterAt index1: Int, withCharacterAt index2: Int) {
		let c1 = _buffer[index1]
		let c2 = _buffer[index2]
		
		_buffer[index1] = c2
		_buffer[index2] = c1
	}

	
	public subscript(index: Int) -> Character {
		get {
			return self.character(at: index)
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
public class XUStringGenerator: IteratorProtocol {
	
	public typealias Element = XUString.XUChar
	
	/// Current index we're at.
	public var currentIndex: Int
	
	/// The string we're iterating.
	public let string: XUString
	
	/// Returns next element.
	public func next() -> XUString.XUChar? {
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

