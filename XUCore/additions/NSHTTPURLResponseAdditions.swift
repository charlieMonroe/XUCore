//
//  NSHTTPURLResponseAdditions.swift
//  XUCore
//
//  Created by Charlie Monroe on 11/9/15.
//  Copyright © 2015 Charlie Monroe Software. All rights reserved.
//

import Foundation

public extension NSHTTPURLResponse {
	
	/// Returns whether the statusCode of self is > 200 and < 300.
	public var statusCodeWithin200Range: Bool {
		return self.statusCode >= 200 && self.statusCode < 300
	}
	
}



