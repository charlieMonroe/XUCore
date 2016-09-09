//
//  NSMutableURLRequestAdditions.swift
//  XUCore
//
//  Created by Charlie Monroe on 11/10/15.
//  Copyright © 2015 Charlie Monroe Software. All rights reserved.
//

import Foundation

/// Value for the accept/content header field.
@available(*, deprecated, renamed: "NSURLRequest.ContentType.JSON")
public let XUMutableURLRequestJSONHeaderFieldValue = "application/json;charset=UTF-8"

/// Value for the accept/content header field.
@available(*, deprecated, renamed: "NSURLRequest.ContentType.XML")
public let XUMutableURLRequestXMLHeaderFieldValue = "application/xml;charset=UTF-8"

/// Value for the accept/content header field.
@available(*, deprecated, renamed: "NSURLRequest.ContentType.WWWForm")
public let XUMutableURLRequestWWWFormHeaderFieldValue = "application/x-www-form-urlencoded;charset=UTF-8"

public extension URLRequest {
	
	public struct ContentType {
		
		/// Content-Type: application/json
		public static let JSON = "application/json;charset=UTF-8"
		
		/// Content-Type: application/xml
		public static let XML = "application/xml;charset=UTF-8"
		
		/// Content-Type: application/x-www-form-urlencoded
		public static let WWWForm = "application/x-www-form-urlencoded;charset=UTF-8"
		
	}
	
}


public extension URLRequest {
	
	public mutating func addAccept(_ accept: String) {
		self.addValue(accept, forHTTPHeaderField: "Accept")
	}
	public mutating func addContentType(_ contentType: String) {
		self.addValue(contentType, forHTTPHeaderField: "Content-Type")
	}
	public mutating func addJSONAcceptToHeader() {
		self.addAccept(URLRequest.ContentType.JSON)
	}
	public mutating func addJSONContentToHeader() {
		self.addContentType(URLRequest.ContentType.JSON)
	}
	public mutating func addMultipartFormDataContentToHeader() {
		self.addContentType("multipart/form-data")
	}
	public mutating func addWWWFormContentToHeader() {
		self.addContentType(URLRequest.ContentType.WWWForm)
	}
	public mutating func addXMLAcceptToHeader() {
		self.addAccept(URLRequest.ContentType.XML)
	}
	public mutating func addXMLContentToHeader() {
		self.addContentType(URLRequest.ContentType.XML)
	}
	
	public var acceptType: String? {
		get {
			return self.value(forHTTPHeaderField: "Accept")
		}
		set {
			self.setValue(newValue, forHTTPHeaderField: "Accept")
		}
	}
	
	public var contentType: String? {
		get {
			return self.value(forHTTPHeaderField: "Content-Type")
		}
		set {
			self.setValue(newValue, forHTTPHeaderField: "Content-Type")
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
			return self.value(forHTTPHeaderField: "Referer")
		}
		set {
			self.setValue(newValue, forHTTPHeaderField: "Referer")
		}
	}
	
	public mutating func setFormBody(_ formBody: [String : String]) {
		let bodyString = formBody.urlQueryString
		self.httpBody = bodyString.data(using: String.Encoding.utf8)
	}
	public mutating func setJSONBody(_ obj: Any) {
		self.httpBody = try? JSONSerialization.data(withJSONObject: obj, options: JSONSerialization.WritingOptions())
	}
	public mutating func setUsername(_ name: String, andPassword password: String) {
		guard let b64 = "\(name):\(password)".data(using: String.Encoding.utf8)?.base64EncodedString(options: NSData.Base64EncodingOptions()) else {
			XULog("Failed to set name and password - cannot create a base64-encoded string!")
			return
		}
		self.addValue("Basic \(b64)", forHTTPHeaderField: "Authorization")
	}
	
	/// You can subscript the URL request and get/set HTTP header fields.
	public subscript(field: String) -> String? {
		get {
			return self.value(forHTTPHeaderField: field)
		}
		set {
			self.setValue(newValue, forHTTPHeaderField: field)
		}
	}
	
	public var userAgent: String? {
		get {
			return self.value(forHTTPHeaderField: "User-Agent")
		}
		set {
			self.setValue(newValue, forHTTPHeaderField: "User-Agent")
		}
	}
}

