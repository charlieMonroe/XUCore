//
//  NSHTTPURLResponseAdditions.swift
//  XUCore
//
//  Created by Charlie Monroe on 11/9/15.
//  Copyright © 2015 Charlie Monroe Software. All rights reserved.
//

import Foundation

/// Date formatter used for parsing the Date header field.
private let _dateFormatter: DateFormatter = {
	let dateFormatter = DateFormatter()
	dateFormatter.dateFormat = "EEEE, dd LLL yyyy HH:mm:ss zzz"
	return dateFormatter
}()

extension HTTPURLResponse {
	
	
	/// Return Content-Type from allHeaderFields
	public var contentType: String? {
		return self.allHeaderFields["Content-Type"] as? String
	}
	
	/// Returns a parsed date from the Date header field.
	public var date: Date? {
		return (self.allHeaderFields["Date"] as? String).flatMap(_dateFormatter.date(from:))
	}
	
	/// Returns whether the statusCode of self is > 200 and < 300.
	public var isStatusCodeWithin200Range: Bool {
		return self.statusCode >= 200 && self.statusCode < 300
	}
	
}



