//
//  URLTests.swift
//  XUCore
//
//  Created by Charlie Monroe on 2/8/17.
//  Copyright © 2017 Charlie Monroe Software. All rights reserved.
//

import Foundation
import XCTest

class URLTests: XCTestCase {
	
	func testAppendingQuery() {
		let url = URL(string: "http://apple.com/")!
		let updatedURL = url.updatingQuery(to: [
			"c": "http://"
		])
		
		XCTAssert(updatedURL.absoluteString == "http://apple.com/?c=http%3A%2F%2F", "URL: \(updatedURL)")
	}
	
	
}

