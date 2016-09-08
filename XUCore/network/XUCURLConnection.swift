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
open class XUCURLConnection: NSObject {
	
	/// Returns if the response is within 200-299 range.
	open class func connectionResponseWithin200Range(_ data: Data) -> Bool {
		guard let response = String(data: data) else {
			return false
		}
		
		XULog("response \(response)")
		let responseCode = response.integerValue
		return responseCode >= 200 && responseCode < 300
	}
	
	fileprivate var _headerFields: [String] = [ ]
	
	/// If set to true, the connection follows redirects.
	open var allowsRedirects: Bool = false
	
	/// Allows custom URL. By default, contains the same value as URL
	open var forcedURLString: String
	
	/// HTTP body.
	open var HTTPBody: String?
	
	/// HTTP method used.
	open var HTTPMethod: String = "GET"
	
	/// If true, ignores invalid certificates.
	open var ignoresInvalidCertificates: Bool = false
	
	/// If true, the response data contains header fields.
	open var includeHeadersInResponse: Bool = false
	
	/// If set to a non-null value, Basic AUTH is used.
	fileprivate(set) open var password: String?
	
	/// If set to true, the request only gets the response code (doesn't download
	/// the body of the response).
	open var responseCodeOnly: Bool = false
	
	/// If initialized with NSURL, this property contains the URL
	open let url: URL?
	
	/// If set to a non-null value, Basic AUTH is used.
	fileprivate(set) open var username: String?
	
	
	
	/// Adds a custom header field
	open func addHeaderField(_ field: String) {
		_headerFields.append(field)
	}
	
	/// Adds JSON to the accept header field
	open func addJSONAcceptToHeader() {
		self.addHeaderField("Accept: application/json")
	}
	
	/// Adds JSON to the content header field
	open func addJSONContentToHeader() {
		self.addHeaderField("Content-Type: application/json")
	}
	
	/// Adds X-WWW-FORM-URLENCODED to the accept header field
	open func addURLEncodedWebFormContentToHeader() {
		self.addHeaderField("Content-Type: application/x-www-form-urlencoded")
	}
	
	/// Adds XML to the accept header field
	open func addXMLAcceptToHeader() {
		self.addHeaderField("Accept: application/xml")
	}
	
	/// Adds XML to the content header field
	open func addXMLContentToHeader() {
		self.addHeaderField("Content-Type: application/xml")
	}
	
	/// Inits with URLString.
	public init(URLString: String) {
		self.forcedURLString = URLString
		self.url = nil
		
		super.init()
	}
	
	/// Inits with URL
	public init(URL: URL) {
		self.url = URL
		self.forcedURLString = URL.absoluteString
		
		super.init()
	}
	
	/// Sends a synchronous request and returns data. Always nonnull.
	open func sendSynchronousRequest() -> Data {
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
		if self.username != nil && self.password != nil {
			args.append("-u")
			args.append("\(self.username!):\(self.password!)")
			
		}
		if UserDefaults.standard.bool(forKey: XUCURLConnectionIgnoreInvalidCertificatesDefaultsKey) || self.ignoresInvalidCertificates {
			args.append("-k")
			
		}
		
		args.append(self.forcedURLString)
		
		if self.responseCodeOnly {
			args.append("-o")
			args.append("/dev/null")
		}
		
		if XUDebugLog.isLoggingEnabled {
			var argsCopy = args
			if var userIndex = argsCopy.index(of: "-u") {
				userIndex += 1
				
				var authFieldString = argsCopy[userIndex]
				if authFieldString.range(of: "\n") != nil {
					XULog("WARNING: new line in username or password")
				}
				
				let components = authFieldString.components(separatedBy: ":")
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
		
		let pipe = Pipe()
		let t = Process()
		t.launchPath = "/usr/bin/curl"
		t.arguments = args
		t.standardOutput = pipe
		t.standardError = Pipe()
		t.launch()
		
		let content = NSMutableData()
		let handle = pipe.fileHandleForReading
		
		while true {
			let data = handle.availableData
			if data.count == 0 || !t.isRunning {
				break
			}
			
			content.append(data)
		}
		
		t.waitUntilExit()
		return content as Data
	}
	
	/// Uses self.sendSynchronousRequest and then attempts to deserialize the data
	open func sendSynchronousRequestAndReturnJSONObject() -> AnyObject? {
		let data = self.sendSynchronousRequest()
		let obj = try? JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions())
		if obj == nil {
			XULog("failed to deserialize JSON data (\(data))")
		}
		
		return obj as AnyObject?
	}
	
	/// Sets HTTP body data and sets the method to POST if POST is true
	open func setHTTPBody(_ data: String, withPOSTRequest POST: Bool = true) {
		self.HTTPBody = data
		self.HTTPMethod = "POST"
	}
	
	/// Sets username and password.
	open func setUsername(_ name: String, andPassword pass: String) {
		self.username = name
		self.password = pass
	}
	
	/// Sets a value for header field. The value may be anything.
	open func setValue(_ value: AnyObject, forHTTPHeaderField field: String) {
		_headerFields.append("\(field): \(value)")
	}
	
}
