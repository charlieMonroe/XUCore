//
//  DataTests.swift
//  XUCore
//
//  Created by Charlie Monroe on 1/24/17.
//  Copyright © 2017 Charlie Monroe Software. All rights reserved.
//

import XCTest

class DataTests: XCTestCase {
	
	func testTrailingZeroes() {
		let data = Data(bytes: [120, 130, 0])
		XCTAssert(data.count == 3)
		
		let trimmedData = data.trimmingTrailingZeros
		XCTAssert(trimmedData.count == 2)
		
		_ = Data().trimmingTrailingZeros
		
		let zeroData = Data(bytes: Array<UInt8>(repeating: 0, count: 100))
		XCTAssert(zeroData.trimmingTrailingZeros.isEmpty)
	}
	
}
