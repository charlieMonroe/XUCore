//
//  CharacterExtensions.swift
//  XUCore
//
//  Created by Charlie Monroe on 10/29/15.
//  Copyright © 2015 Charlie Monroe Software. All rights reserved.
//

import Foundation

extension Character {
	
	/// Returns true if the character is a member of character set.
	func isMemberOfCharacterSet(characterSet: NSCharacterSet) -> Bool {
		return characterSet.characterIsMember(String(self).utf16.first!)
	}
	
}

