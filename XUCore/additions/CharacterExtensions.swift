//
//  CharacterExtensions.swift
//  XUCore
//
//  Created by Charlie Monroe on 10/29/15.
//  Copyright © 2015 Charlie Monroe Software. All rights reserved.
//

import Foundation

extension Character {
	
	/// Returns a random character from a range. The range represents UTF8 codes.
	public static func randomCharacter(in range: Range<Int>) -> Character {
		let randomInt = XURandomGenerator.sharedGenerator.randomUnsignedIntegerInRange(UInt(range.lowerBound)..<UInt(range.upperBound))
		return Character(UnicodeScalar(UInt32(randomInt))!)
	}
	
	/// Returns a random ASCII character (0-127).
	public static var randomASCIICharacter: Character {
		return self.randomCharacter(in: 0 ..< 127)
	}
	
	/// Returns a random letter character (a-Z).
	public static var randomLetterCharacter: Character {
		// A = 0x41, Z = 0x5a, a = 0x61, z = 0x7a
		
		// What we're going to do is to get a random from A-Z and then get another
		// random byte - which is positive, we add 0x20 to lower-case the char.
		
		var randomInt = XURandomGenerator.sharedGenerator.randomUnsignedIntegerInRange(0x41..<0x5a)
		if XURandomGenerator.sharedGenerator.randomBool {
			randomInt += 0x20
		}
		
		return Character(UnicodeScalar(UInt32(randomInt))!)
	}
	
	/// Returns true if `self` is < 128.
	public var isASCII: Bool {
		return self.unicodeScalarValue < 128
	}
	
	/// Returns true if `self` is < 128 or self.isMemberOfCharacterSet(NSCharacterSet.punctuationCharacterSet())
	public var isASCIIOrPunctuation: Bool {
		return self.isASCII || self.isMember(of: CharacterSet.punctuationCharacters)
	}
	
	/// Returns true iff `self` is a-z or A-Z.
	public var isASCIILetter: Bool {
		return self.isLowercaseASCIILetter || self.isUppercaseASCIILetter
	}
	
	/// Returns true iff `self` is 0-9.
	public var isASCIINumber: Bool {
		return self.unicodeScalarValue >= Character("0").unicodeScalarValue && self.unicodeScalarValue <= Character("9").unicodeScalarValue
	}
	
	/// Returns true iff `self` is a-z.
	public var isLowercaseASCIILetter: Bool {
		return self.unicodeScalarValue >= Character("a").unicodeScalarValue && self.unicodeScalarValue <= Character("z").unicodeScalarValue
	}
	
	/// Returns true if the character is a member of character set.
	public func isMember(of characterSet: CharacterSet) -> Bool {
		return characterSet.contains(UnicodeScalar(String(self).utf16.first!)!)
	}
	
	/// Returns true iff `self` is A-Z.
	public var isUppercaseASCIILetter: Bool {
		return self.unicodeScalarValue >= Character("A").unicodeScalarValue && self.unicodeScalarValue <= Character("Z").unicodeScalarValue
	}
	
	public init(_ byte: UInt8) {
		self.init(UnicodeScalar(UInt32(byte))!)
	}
	
	/// Returns the value of the character as viewed in UTF8
	public var UTF8Value: UInt8 {
		return String(self).utf8.first!
	}

	/// Returns the value of the character as viewed in UTF16
	public var unicodeScalarValue: UInt16 {
		return String(self).utf16.first!
	}

	@available(*, deprecated, renamed: "randomCharacter(in:)")
	public static func randomCharacterInRange(_ range: Range<Int>) -> Character {
		return self.randomCharacter(in: range)
	}
	
	@available(*, deprecated, renamed: "isMember(of:)")
	public func isMemberOfCharacterSet(_ characterSet: CharacterSet) -> Bool {
		return self.isMember(of: characterSet)
	}
}

