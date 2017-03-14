//
//  StringTests.swift
//  XUCore
//
//  Created by Charlie Monroe on 1/24/17.
//  Copyright © 2017 Charlie Monroe Software. All rights reserved.
//

import XCTest

class StringTests: XCTestCase {
	
	func testHexConversion() {
		XCTAssert("0x0a".hexValue == 10)
		XCTAssert("0a".hexValue == 10)
		XCTAssert("0A".hexValue == 10)
	}
	
	func testOctalConversion() {
		XCTAssert("00".octalValue == 0)
		XCTAssert("11".octalValue == 9)
		XCTAssert("18".octalValue == 16)
	}
	
	func testQueryDictFromString() {
		let queryString1 = "a=b&c=d"
		let queryDict1 = queryString1.urlQueryDictionary
		XCTAssert(queryDict1["a"] == "b" && queryDict1["c"] == "d")
		
		let queryString2 = "a=&c=d"
		let queryDict2 = queryString2.urlQueryDictionary
		XCTAssert(queryDict2["a"] == "" && queryDict2["c"] == "d")
		
		let queryString3 = "a=b&c="
		let queryDict3 = queryString3.urlQueryDictionary
		XCTAssert(queryDict3["a"] == "b" && queryDict3["c"] == "")
	}
	
	func testEncodingIllegalURLCharacters() {
		let token = "gKkI/pXui2dhd+bJUmfC4He0TruYdyBM1qyiDkQAAAABAAAAAFiJ1yZyYXcAAAAA"
		XCTAssert(token.encodingIllegalURLCharacters == "gKkI%2FpXui2dhd+bJUmfC4He0TruYdyBM1qyiDkQAAAABAAAAAFiJ1yZyYXcAAAAA", token.encodingIllegalURLCharacters)
		
		XCTAssert("http://www.dilidili.wang/watch3/54476/".encodingIllegalURLCharacters == "http%3A%2F%2Fwww.dilidili.wang%2Fwatch3%2F54476%2F")
		
		XCTAssert("serepeticka.&".encodingIllegalURLCharacters == "serepeticka.%26")
	}
	
	func testUTF8StringToData() {
		let utf8String = "ěščřžýáíé"
		XCTAssert(utf8String.data(using: .utf8) == utf8String.utf8Data)
	}
	
}

