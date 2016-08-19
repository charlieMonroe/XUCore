//
//  NSMutableURLRequestAdditions.swift
//  XUCore
//
//  Created by Charlie Monroe on 11/10/15.
//  Copyright © 2015 Charlie Monroe Software. All rights reserved.
//

import Foundation

/// Value for the accept/content header field.
@available(*, deprecated, renamed="NSURLRequest.ContentType.JSON")
public let XUMutableURLRequestJSONHeaderFieldValue = "application/json;charset=UTF-8"

/// Value for the accept/content header field.
@available(*, deprecated, renamed="NSURLRequest.ContentType.XML")
public let XUMutableURLRequestXMLHeaderFieldValue = "application/xml;charset=UTF-8"

/// Value for the accept/content header field.
@available(*, deprecated, renamed="NSURLRequest.ContentType.WWWForm")
public let XUMutableURLRequestWWWFormHeaderFieldValue = "application/x-www-form-urlencoded;charset=UTF-8"

public extension NSURLRequest {
	
	public struct ContentType {
		
		/// Content-Type: application/json
		public static let JSON = "application/json;charset=UTF-8"
		
		/// Content-Type: application/xml
		public static let XML = "application/xml;charset=UTF-8"
		
		/// Content-Type: application/x-www-form-urlencoded
		public static let WWWForm = "application/x-www-form-urlencoded;charset=UTF-8"
		
	}
	
}


public extension NSMutableURLRequest {
	
	public func addAccept(accept: String) {
		self.addValue(accept, forHTTPHeaderField: "Accept")
	}
	public func addContentType(contentType: String) {
		self.addValue(contentType, forHTTPHeaderField: "Content-Type")
	}
	public func addJSONAcceptToHeader() {
		self.addAccept(NSURLRequest.ContentType.JSON)
	}
	public func addJSONContentToHeader() {
		self.addContentType(NSURLRequest.ContentType.JSON)
	}
	public func addMultipartFormDataContentToHeader() {
		self.addContentType("multipart/form-data")
	}
	public func addWWWFormContentToHeader() {
		self.addContentType(NSURLRequest.ContentType.WWWForm)
	}
	public func addXMLAcceptToHeader() {
		self.addAccept(NSURLRequest.ContentType.XML)
	}
	public func addXMLContentToHeader() {
		self.addContentType(NSURLRequest.ContentType.XML)
	}
	
	public var acceptType: String? {
		get {
			return self.valueForHTTPHeaderField("Accept")
		}
		set {
			self.setValue(newValue, forHTTPHeaderField: "Accept")
		}
	}
	
	public var contentType: String? {
		get {
			return self.valueForHTTPHeaderField("Content-Type")
		}
		set {
			self.setValue(newValue, forHTTPHeaderField: "Content-Type")
		}
	}
	
	public var referer: String? {
		get {
			return self.valueForHTTPHeaderField("Referer")
		}
		set {
			self.setValue(newValue, forHTTPHeaderField: "Referer")
		}
	}
	
	public func setFormBody(formBody: [String : String]) {
		let bodyString = formBody.URLQueryString
		self.HTTPBody = bodyString.dataUsingEncoding(NSUTF8StringEncoding)
	}
	public func setJSONBody(obj: AnyObject) {
		self.HTTPBody = try? NSJSONSerialization.dataWithJSONObject(obj, options: NSJSONWritingOptions())
	}
	public func setUsername(name: String, andPassword password: String) {
		guard let b64 = "\(name):\(password)".dataUsingEncoding(NSUTF8StringEncoding)?.base64EncodedStringWithOptions(NSDataBase64EncodingOptions()) else {
			XULog("Failed to set name and password - cannot create a base64-encoded string!")
			return
		}
		self.addValue("Basic \(b64)", forHTTPHeaderField: "Authorization")
	}
	
	/// You can subscript the URL request and get/set HTTP header fields.
	public subscript(field: String) -> String? {
		get {
			return self.valueForHTTPHeaderField(field)
		}
		set {
			self.setValue(newValue, forHTTPHeaderField: field)
		}
	}
	
	public var userAgent: String? {
		get {
			return self.valueForHTTPHeaderField("User-Agent")
		}
		set {
			self.setValue(newValue, forHTTPHeaderField: "User-Agent")
		}
	}
}

