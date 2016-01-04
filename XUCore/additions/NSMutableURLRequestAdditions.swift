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
		self.addContentType("application/x-www-form-urlencoded")
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
		let b64 = "\(name):\(password)".dataUsingEncoding(NSUTF8StringEncoding)?.base64EncodedStringWithOptions(NSDataBase64EncodingOptions())
		self.addValue("Basic \(b64)", forHTTPHeaderField: "Authorization")
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

