//
//  NSHTTPURLResponseAdditions.swift
//  XUCore
//
//  Created by Charlie Monroe on 11/9/15.
//  Copyright © 2015 Charlie Monroe Software. All rights reserved.
//

import Foundation

public extension HTTPURLResponse {
	
	/// Return Content-Type from allHeaderFields
	public var contentType: String? {
		return self.allHeaderFields["Content-Type"] as? String
	}
	
	@available(*, deprecated, renamed: "isStatusCodeWithin200Range")
	public var statusCodeWithin200Range: Bool {
		return self.isStatusCodeWithin200Range
	}
	
	/// Returns whether the statusCode of self is > 200 and < 300.
	public var isStatusCodeWithin200Range: Bool {
		return self.statusCode >= 200 && self.statusCode < 300
	}
	
}



