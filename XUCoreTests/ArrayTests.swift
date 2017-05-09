//
//  ArrayTests.swift
//  XUCore
//
//  Created by Charlie Monroe on 5/8/17.
//  Copyright © 2017 Charlie Monroe Software. All rights reserved.
//

import XCTest

private func ==(lhs: [[Int]], rhs: [[Int]]) -> Bool {
	guard lhs.count == rhs.count else {
		return false
	}
	
	for i in lhs.indices {
		guard lhs[i] == rhs[i] else {
			return false
		}
	}
	
	return true
}

class ArrayTests: XCTestCase {
	
	func testSplit() {
		XCTAssert([].splitIntoChunks(ofSize: 3) == ([[]] as [[Int]]))
		
		XCTAssert([1].splitIntoChunks(ofSize: 3) == ([[1]] as [[Int]]))
		XCTAssert([1, 2, 3, 4].splitIntoChunks(ofSize: 3) == ([[1, 2, 3], [4]] as [[Int]]))
		XCTAssert([1, 2, 3].splitIntoChunks(ofSize: 3) == ([[1, 2, 3]] as [[Int]]))
		
		XCTAssert([1, 2, 3, 4].splitIntoChunks(ofSize: 2) == ([[1, 2], [3, 4]] as [[Int]]))
		XCTAssert([1, 2, 3, 4, 5].splitIntoChunks(ofSize: 2) == ([[1, 2], [3, 4], [5]] as [[Int]]))
	}
	
}

