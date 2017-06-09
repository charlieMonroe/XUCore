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
		
		return cookies.first { $0.name == name }
	}

	/// Removes all cookies for a particular URL.
	public func removeAllCookies(for url: URL) {
		guard let cookies = self.cookies(for: url) else {
			return
		}
		
		cookies.forEach(self.deleteCookie(_:))
	}
	
}
