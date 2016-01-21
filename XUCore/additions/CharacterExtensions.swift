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
	public static func randomCharacterInRange(range: Range<Int>) -> Character {
		let randomInt = XURandomGenerator.sharedGenerator.randomUnsignedIntegerInRange(Range<UInt>(start: UInt(range.startIndex), end: UInt(range.endIndex)))
		return Character(UnicodeScalar(UInt32(randomInt)))
	}
	
	/// Returns a random ASCII character (0-127).
	public static var randomASCIICharacter: Character {
		return self.randomCharacterInRange(Range<Int>(start: 0, end: 127))
	}
	
	/// Returns a random letter character (a-Z).
	public static var randomLetterCharacter: Character {
		// A = 0x41, Z = 0x5a, a = 0x61, z = 0x7a
		
		// What we're going to do is to get a random from A-Z and then get another
		// random byte - which is positive, we add 0x20 to lower-case the char.
		
		var randomInt = XURandomGenerator.sharedGenerator.randomUnsignedIntegerInRange(Range<UInt>(start: 0x41, end: 0x5a))
		if XURandomGenerator.sharedGenerator.randomBool {
			randomInt += 0x20
		}
		
		return Character(UnicodeScalar(UInt32(randomInt)))
	}
	
	/// Returns true if the character is a member of character set.
	func isMemberOfCharacterSet(characterSet: NSCharacterSet) -> Bool {
		return characterSet.characterIsMember(String(self).utf16.first!)
	}
	
	public init(_ byte: UInt8) {
		self.init(UnicodeScalar(UInt32(byte)))
	}
	
}

