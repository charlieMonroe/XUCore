//
//  DataTests.swift
//  XUCore
//
//  Created by Charlie Monroe on 1/24/17.
//  Copyright © 2017 Charlie Monroe Software. All rights reserved.
//

import XCTest

class DataTests: XCTestCase {
	
	func testByteAtIndex() {
		let range = (0 as UInt8) ..< (10 as UInt8)
		let data = Data(bytes: Array(range))
		
		for i in range {
			XCTAssert(data.byte(at: Int(i)) == i)
		}
	}
	
	func testPrefix() {
		let range = (0 as UInt8) ..< (10 as UInt8)
		let data = Data(bytes: Array(range))
		
		XCTAssert(data.hasPrefix([]))
		XCTAssert(data.hasPrefix(Array(range)))
		XCTAssert(data.hasPrefix([0x00]))
		XCTAssert(data.hasPrefix([0x00, 0x01]))
		XCTAssert(!data.hasPrefix([0x01]))
	}
	
	func testTrailingZeroes() {
		let data = Data(bytes: [120, 130, 0])
		XCTAssert(data.count == 3)
		
		let trimmedData = data.trimmingTrailingZeros
		XCTAssert(trimmedData.count == 2)
		
		_ = Data().trimmingTrailingZeros
		
		let zeroData = Data(bytes: Array<UInt8>(repeating: 0, count: 100))
		XCTAssert(zeroData.trimmingTrailingZeros.isEmpty)
	}
	
	func testSplit() {
		let range = (0 as UInt8) ..< (10 as UInt8)
		let data = Data(bytes: Array(range))
		
		XCTAssert(data.splitIntoParts(ofMaximumSize: 10).count == 1)
		XCTAssert(data.splitIntoParts(ofMaximumSize: 1).count == 10)
		XCTAssert(Data().splitIntoParts(ofMaximumSize: 1).count == 1)
	}
	
}
