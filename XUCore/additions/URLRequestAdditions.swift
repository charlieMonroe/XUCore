//
//  NSMutableURLRequestAdditions.swift
//  XUCore
//
//  Created by Charlie Monroe on 11/10/15.
//  Copyright © 2015 Charlie Monroe Software. All rights reserved.
//

import Foundation


public extension URLRequest {
	
	public struct ContentType: RawRepresentable {
		
		/// Returns a new content type that consists of lhs and rhs.
		public static func +(lhs: ContentType, rhs: ContentType) -> ContentType {
			return ContentType(lhs.rawValue + ", " + rhs.rawValue)
		}
		
		/// Updates lhs so that it consists of lhs and rhs.
		public static func +=(lhs: inout ContentType, rhs: ContentType) {
			lhs = lhs + rhs
		}

		/// Content-Type: "*/*"
		public static let any = ContentType("*/*")
		
		/// Default browser content type - html, xhtml, xml, fallbacking on */*.
		public static let defaultBrowser = ContentType("text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8")
		
		/// Content-Type: "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8"
		public static let html = ContentType("text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8")
		
		/// Content-Type: application/json
		public static let json = ContentType("application/json")

		/// Content-Type: text/plain
		public static let plainText = ContentType("text/plain")
		
		/// Content-Type: application/xml
		public static let xml = ContentType("application/xml")
		
		/// Content-Type: application/x-www-form-urlencoded
		public static let wwwForm = ContentType("application/x-www-form-urlencoded")
		
		
		
		public var rawValue: String
		
		/// Character set of the content type. This is dynamically retrieved from
		/// the raw value.
		public var characterSet: String? {
			get {
				let components = self.rawValue.components(separatedBy: ";")
				guard let charsetComponent = components.first(where: { $0.hasCaseInsensitive(prefix: "charset=") }) else {
					return nil
				}
				
				let startIndex = charsetComponent.index(charsetComponent.startIndex, offsetBy: 8)
				return String(charsetComponent[startIndex...])
			}
			set {
				var components = self.rawValue.components(separatedBy: ";")
				if let index = components.index(where: { $0.hasCaseInsensitive(prefix: "charset=") }) {
					if let value = newValue {
						components[index] = "charset=" + value
					} else {
						components.remove(at: index)
					}
				} else if let value = newValue {
					components.append("charset=" + value)
				}
				self.rawValue = components.joined(separator: ";")
			}
		}
		
		public init(rawValue: String) {
			self.rawValue = rawValue
		}
		
		public init(_ rawValue: String) {
			self.rawValue = rawValue
		}
		
		/// Initializes self with a particular type and charset.
		public init(type: String, characterSet: String) {
			self.rawValue = type + ";charset=" + characterSet
		}
		
		/// Creates a copy with a modified character set.
		public func settingCharacterSet(to characterSet: String?) -> ContentType {
			var copy = self
			copy.characterSet = characterSet
			return copy
		}
		
	}
	
	/// Structure representing a User Agent.
	public struct UserAgent: RawRepresentable {
		
		/// Default user agent.
		public static let `default`: UserAgent = macOS.Safari10
		
		/// Default user agent for mobile.
		public static let defaultMobile: UserAgent = iOS.Safari8
		
		/// Contains macOS user agents.
		public struct macOS {
			
			/// Chrome 56 on macOS 10.12.3.
			public static let Chrome56: UserAgent = UserAgent("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/56.0.2924.87 Safari/537.36")
			
			/// Firefox 54 on macOS 10.12.
			public static let Firefox54: UserAgent = UserAgent("Mozilla/5.0 (Macintosh; Intel Mac OS X 10.12; rv:54.0) Gecko/20100101 Firefox/54.0")
			
			/// Safari on macOS 10.12 (10.0)
			public static let Safari10: UserAgent = UserAgent("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12) AppleWebKit/602.1.50 (KHTML, like Gecko) Version/10.0 Safari/602.1.50")
			
		}
		
		/// Contains iOS user agents.
		public struct iOS {
			/// Safari on iOS 8.1
			public static let Safari8: UserAgent = UserAgent("Mozilla/5.0 (iPad; CPU OS 8_1 like Mac OS X) AppleWebKit/600.1.4 (KHTML, like Gecko) Version/8.0 Mobile/12B410 Safari/600.1.4")
		}
		
		
		/// Raw value of the user agent.
		public var rawValue: String
		
		/// Initializes with a raw value.
		public init(rawValue: String) {
			self.rawValue = rawValue
		}
		
		/// Initializes with a raw value.
		public init(_ rawValue: String) {
			self.rawValue = rawValue
		}

	}
	
}

public protocol XUHTTPHeaderFields {
	
	/// Subscript is all that is required.
	subscript(field: String) -> String? { get set }
	
}

extension XUHTTPHeaderFields {
	
	public var acceptType: URLRequest.ContentType? {
		get {
			return self["Accept"].flatMap(URLRequest.ContentType.init(rawValue:))
		}
		set {
			self["Accept"] = newValue?.rawValue
		}
	}
	
	public var contentType: URLRequest.ContentType? {
		get {
			return self["Content-Type"].flatMap(URLRequest.ContentType.init(rawValue:))
		}
		set {
			self["Content-Type"] = newValue?.rawValue
		}
	}
	
	public var cookies: String? {
		get {
			return self["Cookie"]
		}
		set {
			self["Cookie"] = newValue
		}
	}
	
	public var forwardedForIP: String? {
		get {
			return self["X-Forwarded-For"]
		}
		set {
			self["X-Forwarded-For"] = newValue
		}
	}
	
	public var origin: String? {
		get {
			return self["Origin"]
		}
		set {
			self["Origin"] = newValue
		}
	}
	
	public var referer: String? {
		get {
			return self["Referer"]
		}
		set {
			self["Referer"] = newValue
		}
	}
	
	public mutating func setBasicAuthentication(user: String, password: String) {
		guard let b64 = "\(user):\(password)".data(using: String.Encoding.utf8)?.base64EncodedString() else {
			XULog("Failed to set name and password - cannot create a base64-encoded string!")
			return
		}
		self["Authorization"] = "Basic \(b64)"
	}
	
	public mutating func setBearerAuthorization(with token: String) {
		self["Authorization"] = "Bearer " + token
	}
	
	/// User agent.
	public var userAgent: URLRequest.UserAgent? {
		get {
			guard let userAgent = self["User-Agent"] else {
				return nil
			}
			
			return URLRequest.UserAgent(rawValue: userAgent)
		}
		set {
			self["User-Agent"] = newValue?.rawValue
		}
	}
	
}



extension URLRequest: XUHTTPHeaderFields {
	
	/// You can subscript the URL request and get/set HTTP header fields.
	public subscript(field: String) -> String? {
		get {
			return self.allHTTPHeaderFields?[field]
		}
		set {
			self.setValue(newValue, forHTTPHeaderField: field)
		}
	}

	
	@available(*, deprecated, message: "Use the setters as that's what you most likely want anyway.")
	public mutating func addAccept(_ accept: String) {
		self.addValue(accept, forHTTPHeaderField: "Accept")
	}
	
	@available(*, deprecated, message: "Use the setters as that's what you most likely want anyway.")
	public mutating func addContentType(_ contentType: String) {
		self.addValue(contentType, forHTTPHeaderField: "Content-Type")
	}
	
	@available(*, deprecated, message: "Use the setters as that's what you most likely want anyway.")
	public mutating func addJSONAcceptToHeader() {
		self.addAccept(URLRequest.ContentType.json.rawValue)
	}
	
	@available(*, deprecated, message: "Use the setters as that's what you most likely want anyway.")
	public mutating func addJSONContentToHeader() {
		self.addContentType(URLRequest.ContentType.json.rawValue)
	}
	
	@available(*, deprecated, message: "Use the setters as that's what you most likely want anyway.")
	public mutating func addMultipartFormDataContentToHeader() {
		self.addContentType("multipart/form-data")
	}
	
	@available(*, deprecated, message: "Use the setters as that's what you most likely want anyway.")
	public mutating func addWWWFormContentToHeader() {
		self.addContentType(URLRequest.ContentType.wwwForm.rawValue)
	}
	
	@available(*, deprecated, message: "Use the setters as that's what you most likely want anyway.")
	public mutating func addXMLAcceptToHeader() {
		self.addAccept(URLRequest.ContentType.xml.rawValue)
	}
	
	@available(*, deprecated, message: "Use the setters as that's what you most likely want anyway.")
	public mutating func addXMLContentToHeader() {
		self.addContentType(URLRequest.ContentType.xml.rawValue)
	}
	
	@available(*, deprecated, renamed: "setBasicAuthentication(user:password:)")
	public mutating func setUsername(_ name: String, andPassword password: String) {
		self.setBasicAuthentication(user: name, password: password)
	}
	
	
	public mutating func setFormBody(_ formBody: [String : String]) {
		let bodyString = formBody.urlQueryString
		self.httpBody = bodyString.data(using: String.Encoding.utf8)
	}
	public mutating func setJSONBody(_ obj: Any) {
		self.httpBody = try? JSONSerialization.data(withJSONObject: obj)
	}
	
}

