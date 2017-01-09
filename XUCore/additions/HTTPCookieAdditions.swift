//
//  HTTPCookieAdditions.swift
//  XUCore
//
//  Created by Charlie Monroe on 1/4/17.
//  Copyright © 2017 Charlie Monroe Software. All rights reserved.
//

import Foundation

public extension HTTPCookieStorage {
	
	/// Looks through cookies returned by cookies(for:) for a cookie named "name".
	public func cookie(named name: String, for url: URL) -> HTTPCookie? {
		guard let cookies = self.cookies(for: url) else {
			return nil
		}
		
		return cookies.find { $0.name == name }
	}
	
}
