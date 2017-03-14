//
//  CharacterTests.swift
//  XUCore
//
//  Created by Charlie Monroe on 3/12/17.
//  Copyright © 2017 Charlie Monroe Software. All rights reserved.
//

import XCTest

class CharacterTests: XCTestCase {
	
	func testASCII() {
		XCTAssert(!Character("å").isASCII)
	}
	
}

