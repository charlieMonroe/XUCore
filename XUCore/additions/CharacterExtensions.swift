//
//  CharacterExtensions.swift
//  XUCore
//
//  Created by Charlie Monroe on 10/29/15.
//  Copyright © 2015 Charlie Monroe Software. All rights reserved.
//

import Foundation

extension Character {
	
	/// Null character (0).
	public static let null: Character = Character(0)
	
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
	
	/// Returns a random letter character (a-Z).
	public static var randomLetterOrNumberCharacter: Character {
		if XURandomGenerator.shared.randomBoolean {
			return self.randomLetterCharacter
		}
		
		return self.randomCharacter(in: 0x30 ..< 0x3A)
	}
	
	/// Returns true if the character is a member of character set.
	public func isMember(of characterSet: CharacterSet) -> Bool {
		guard let scalar = UnicodeScalar(String(self).utf16.first!) else {
			return false
		}
		return characterSet.contains(scalar)
	}
	
	public init(_ byte: UInt8) {
		self.init(UnicodeScalar(UInt32(byte))!)
	}

	/// Returns the value of the character as viewed in UTF16. Note that
	/// if the character requires multiple UInt16 for representation in UTF16, then
	/// only the first UInt16 is returned.
	public var unicodeScalarValue: UInt16 {
		return String(self).utf16.first!
	}
	
}

