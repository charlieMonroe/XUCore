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
		let convertedRange: Range<UInt32> = range.converted(to: UInt32.self)
		let randomInt: UInt32 = XURandomGenerator.shared.randomInteger(in: convertedRange)
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
		
		var randomInt = XURandomGenerator.shared.randomInteger(in: 0x41 ..< 0x5a)
		if XURandomGenerator.shared.randomBoolean {
			randomInt += 0x20
		}
		
		return Character(UnicodeScalar(UInt32(randomInt))!)
	}
	
	/// Returns true if `self` is < 128 and can be represented by a single UTF8
	/// character.
	public var isASCII: Bool {
		return String(self).utf8.count == 1 && self.unicodeScalarValue < 128
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
		if !self.isASCII {
			return false
		}
		return self.unicodeScalarValue >= Character("0").unicodeScalarValue && self.unicodeScalarValue <= Character("9").unicodeScalarValue
	}
	
	/// Returns true iff `self` is a-z.
	public var isLowercaseASCIILetter: Bool {
		if !self.isASCII {
			return false
		}
		return self.unicodeScalarValue >= Character("a").unicodeScalarValue && self.unicodeScalarValue <= Character("z").unicodeScalarValue
	}
	
	/// Returns true if the character is a member of character set.
	public func isMember(of characterSet: CharacterSet) -> Bool {
		return characterSet.contains(UnicodeScalar(String(self).utf16.first!)!)
	}
	
	/// Returns true iff `self` is A-Z.
	public var isUppercaseASCIILetter: Bool {
		if !self.isASCII {
			return false
		}
		return self.unicodeScalarValue >= Character("A").unicodeScalarValue && self.unicodeScalarValue <= Character("Z").unicodeScalarValue
	}
	
	public init(_ byte: UInt8) {
		self.init(UnicodeScalar(UInt32(byte))!)
	}
	
	/// Returns the value of the first character when viewed in UTF8. Note that 
	/// if the character requires multiple bytes for representation in UTF8, then
	/// only the first byte is returned.
	public var asciiValue: UInt8 {
		return String(self).utf8.first!
	}

	/// Returns the value of the character as viewed in UTF16. Note that
	/// if the character requires multiple UInt16 for representation in UTF16, then
	/// only the first UInt16 is returned.
	public var unicodeScalarValue: UInt16 {
		return String(self).utf16.first!
	}
	
}

