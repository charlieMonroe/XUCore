//
//  HTTPCookieAdditions.swift
//  XUCore
//
//  Created by Charlie Monroe on 1/4/17.
//  Copyright © 2017 Charlie Monroe Software. All rights reserved.
//

import Foundation

public extension HTTPCookie {
	
	/// Returns true if the cookie has an expiresDate and it's in the past.
	var isExpired: Bool {
		guard let date = self.expiresDate, date.isPast else {
			return false
		}
		
		return true
	}
	
	/// Convenience init. It takes the domain from the URL. If path is not specified,
	/// a "/" is used. Returns nil if the url's domain is nil.
	convenience init?(url: URL, path: String = "/", name: String, value: String) {
		guard let host = url.host else {
			return nil
		}
		
		self.init(domain: host, path: path, name: name, value: value)
	}
	
	/// Convenience init.
	convenience init?(domain: String, path: String = "/", name: String, value: String) {
		self.init(properties: [.name: name, .value: value, .path: path, .domain: domain])
	}
	
}


public extension HTTPCookieStorage {
	
	/// Looks through cookies returned by cookies(for:) for a cookie named "name".
	func cookie(named name: String, for url: URL) -> HTTPCookie? {
		guard let cookies = self.cookies(for: url) else {
			return nil
		}
		
		return cookies.first { $0.name == name }
	}

	/// Removes all cookies for a particular URL.
	func removeAllCookies(for url: URL) {
		guard let cookies = self.cookies(for: url) else {
			return
		}
		
		cookies.forEach(self.deleteCookie(_:))
	}
	
}
