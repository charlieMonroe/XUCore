//
//  XUCURLConnection.swift
//  XUCore
//
//  Created by Charlie Monroe on 11/5/15.
//  Copyright © 2015 Charlie Monroe Software. All rights reserved.
//

import Cocoa

public let XUCURLConnectionIgnoreInvalidCertificatesDefaultsKey = "XUCURLConnectionIgnoreInvalidCertificates"

/// This class is somewhat similar to NSURLConnection, except supports only HTTP
/// and internally uses the CURL command.
public class XUCURLConnection: NSObject {
	
	/// Returns if the response is within 200-299 range.
	public class func connectionResponseWithin200Range(data: NSData) -> Bool {
		guard let response = NSString(data: data) else {
			return false
		}
		
		XULog("response \(response)")
		let responseCode = response.integerValue
		return responseCode >= 200 && responseCode < 300
	}
	
	private var _headerFields: [String] = [ ]
	
	/// If set to true, the connection follows redirects.
	public var allowsRedirects: Bool = false
	
	/// Allows custom URL. By default, contains the same value as URL
	public var forcedURLString: String
	
	/// HTTP body.
	public var HTTPBody: String?
	
	/// HTTP method used.
	public var HTTPMethod: String = "GET"
	
	/// If true, ignores invalid certificates.
	public var ignoresInvalidCertificates: Bool = false
	
	/// If true, the response data contains header fields.
	public var includeHeadersInResponse: Bool = false
	
	/// If set to a non-null value, Basic AUTH is used.
	private(set) public var password: String?
	
	/// If set to true, the request only gets the response code (doesn't download
	/// the body of the response).
	public var responseCodeOnly: Bool = false
	
	/// If initialized with NSURL, this property contains the URL
	public let URL: NSURL?
	
	/// If set to a non-null value, Basic AUTH is used.
	private(set) public var username: String?
	
	
	
	/// Adds a custom header field
	public func addHeaderField(field: String) {
		_headerFields.append(field)
	}
	
	/// Adds JSON to the accept header field
	public func addJSONAcceptToHeader() {
		self.addHeaderField("Accept: application/json")
	}
	
	/// Adds JSON to the content header field
	public func addJSONContentToHeader() {
		self.addHeaderField("Content-Type: application/json")
	}
	
	/// Adds X-WWW-FORM-URLENCODED to the accept header field
	public func addURLEncodedWebFormContentToHeader() {
		self.addHeaderField("Content-Type: application/x-www-form-urlencoded")
	}
	
	/// Adds XML to the accept header field
	public func addXMLAcceptToHeader() {
		self.addHeaderField("Accept: application/xml")
	}
	
	/// Adds XML to the content header field
	public func addXMLContentToHeader() {
		self.addHeaderField("Content-Type: application/xml")
	}
	
	/// Inits with URLString.
	public init(URLString: String) {
		self.forcedURLString = URLString
		self.URL = nil
		
		super.init()
	}
	
	/// Inits with URL
	public init(URL: NSURL) {
		self.URL = URL
		self.forcedURLString = URL.absoluteString
		
		super.init()
	}
	
	/// Sends a synchronous request and returns data. Always nonnull.
	public func sendSynchronousRequest() -> NSData {
		var args: [String] = [ ]
		if self.responseCodeOnly {
			args.append("-sL")
			args.append("-w")
			args.append("%{http_code}")
		} else {
			if self.includeHeadersInResponse {
				args.append("-i")
			}
		}
		
		if self.HTTPBody != nil {
			args.append("-d")
			args.append(self.HTTPBody!)
		}
		
		args.append("-X")
		args.append(self.HTTPMethod)
		
		if self.allowsRedirects {
			args.append("-L")
			
		}
		for headerField in _headerFields {
			args.append("-H")
			args.append(headerField)
			
		}
		if self.username != nil&&self.password != nil {
			args.append("-u")
			args.append("\(self.username):\(self.password)")
			
		}
		if NSUserDefaults.standardUserDefaults().boolForKey(XUCURLConnectionIgnoreInvalidCertificatesDefaultsKey) || self.ignoresInvalidCertificates {
			args.append("-k")
			
		}
		
		args.append(self.forcedURLString)
		
		if self.responseCodeOnly {
			args.append("-o")
			args.append("/dev/null")
		}
		
		if XUShouldLog() {
			var argsCopy = args
			if var userIndex = argsCopy.indexOf("-u") {
				++userIndex
				
				var authFieldString = argsCopy[userIndex]
				if authFieldString.rangeOfString("\n") != nil {
					XULog("WARNING: new line in username or password")
				}
				
				let components = authFieldString.componentsSeparatedByString(":")
				if components[1] == "X" {
					// API key
					authFieldString = "***API_KEY***:X"
				} else {
					authFieldString = "\(components[0]):***PASSWORD***"
				}
				
				argsCopy[userIndex] = authFieldString
			}
			
			XULog("\(argsCopy)")
		}
		
		let pipe = NSPipe()
		let t = NSTask()
		t.launchPath = "/usr/bin/curl"
		t.arguments = args
		t.standardOutput = pipe
		t.standardError = NSPipe()
		t.launch()
		
		let content = NSMutableData()
		let handle = pipe.fileHandleForReading
		
		while true {
			let data = handle.availableData
			if data.length == 0 || !t.running {
				break
			}
			
			content.appendData(data)
		}
		
		t.waitUntilExit()
		return content
	}
	
	/// Uses self.sendSynchronousRequest and then attempts to deserialize the data
	public func sendSynchronousRequestAndReturnJSONObject() -> AnyObject? {
		let data = self.sendSynchronousRequest()
		let obj = try? NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions())
		if obj == nil {
			XULog("failed to deserialize JSON data (\(data))")
		}
		
		return obj
	}
	
	/// Sets HTTP body data and sets the method to POST if POST is true
	public func setHTTPBody(data: String, withPOSTRequest POST: Bool = true) {
		self.HTTPBody = data
		self.HTTPMethod = "POST"
	}
	
	/// Sets username and password.
	public func setUsername(name: String, andPassword pass: String) {
		self.username = name
		self.password = pass
	}
	
	/// Sets a value for header field. The value may be anything.
	public func setValue(value: AnyObject, forHTTPHeaderField field: String) {
		_headerFields.append("\(field): \(value)")
	}
	
}
