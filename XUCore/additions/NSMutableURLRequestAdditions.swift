//
//  NSMutableURLRequestAdditions.swift
//  XUCore
//
//  Created by Charlie Monroe on 11/10/15.
//  Copyright © 2015 Charlie Monroe Software. All rights reserved.
//

import Foundation

/// Value for the accept/content header field.
public let XUMutableURLRequestJSONHeaderFieldValue = "application/json"

/// Value for the accept/content header field.
public let XUMutableURLRequestXMLHeaderFieldValue = "application/xml"

/// Value for the accept/content header field.
public let XUMutableURLRequestWWWFormHeaderFieldValue = "application/x-www-form-urlencoded"

public extension NSMutableURLRequest {
	
	public func addAccept(accept: String) {
		self.addValue(accept, forHTTPHeaderField: "Accept")
	}
	public func addContentType(contentType: String) {
		self.addValue(contentType, forHTTPHeaderField: "Content-Type")
	}
	public func addJSONAcceptToHeader() {
		self.addAccept(XUMutableURLRequestJSONHeaderFieldValue)
	}
	public func addJSONContentToHeader() {
		self.addContentType(XUMutableURLRequestJSONHeaderFieldValue)
	}
	public func addMultipartFormDataContentToHeader() {
		self.addContentType("multipart/form-data")
	}
	public func addWWWFormContentToHeader() {
		self.addContentType(XUMutableURLRequestWWWFormHeaderFieldValue)
	}
	public func addXMLAcceptToHeader() {
		self.addAccept(XUMutableURLRequestXMLHeaderFieldValue)
	}
	public func addXMLContentToHeader() {
		self.addContentType(XUMutableURLRequestXMLHeaderFieldValue)
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

