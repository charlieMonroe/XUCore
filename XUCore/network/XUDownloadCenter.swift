//
//  XUDownloadCenter.swift
//  XUCore
//
//  Created by Charlie Monroe on 2/23/16.
//  Copyright © 2016 Charlie Monroe Software. All rights reserved.
//

import Foundation

public let XUDownloadCenterDefaultUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11) AppleWebKit/601.1.56 (KHTML, like Gecko) Version/9.0 Safari/601.1.56"
public let XUDownloadCenterMobileUserAgent = "Mozilla/5.0 (iPad; CPU OS 8_1 like Mac OS X) AppleWebKit/600.1.4 (KHTML, like Gecko) Version/8.0 Mobile/12B410 Safari/600.1.4"

public enum XUDownloadCenterError {
	
	/// This error represents a state where the NSURLConnection returns nil -
	/// i.e. connection timeout or no internet connection at all.
	case NoInternetConnection
	
	/// This is a specific case which can be used by downloadWebSiteSourceByPostingFormOnPage(*)
	/// methods. It means that there are no input fields available in the source.
	case NoInputFields
	
	/// The download center did load some data, but it cannot be parsed as JSON.
	case InvalidJSONResponse
	
	#if os(OSX)
	/// The download center did load some data, but it cannot be parsed as XML.
	case InvalidXMLResponse
	#endif
	
	/// The download center has downloaded and parsed the JSON, but it cannot
	/// be cast to the correct format.
	case WrongJSONFormat
	
}

/// The protocol defining the owner of the download center. Most of the conformity
/// is optional - see the extension below.
public protocol XUDownloadCenterOwner: AnyObject {
	
	/// Default encoding for web sites. UTF8 by default.
	var defaultSourceEncoding: NSStringEncoding { get }
	
	/// This is called whenever the download center fails to load a webpage, or
	/// parse JSON/XML.
	func downloadCenter(downloadCenter: XUDownloadCenter, didEncounterError error: XUDownloadCenterError)
	
	/// User agent used for downloading websites, XML documents, JSONs.
	var infoPageUserAgent: String { get }
	
	///  Name of the owner. Used for logging, etc.
	var name: String { get }
	
	/// Referer URL.
	var refererURL: NSURL? { get }
	
	/// Possibility to modify the request for downloading a page. No-op by default.
	func setupURLRequest(request: NSMutableURLRequest, forDownloadingPageAtURL pageURL: NSURL)
}

public extension XUDownloadCenterOwner {
	
	/// Possibility to modify the request for downloading a page. No-op by default.
	public func setupURLRequest(request: NSMutableURLRequest, forDownloadingPageAtURL pageURL: NSURL) {
		// No-op
	}
	
	/// Default encoding for web sites. UTF8 by default.
	public var defaultSourceEncoding: NSStringEncoding {
		return NSUTF8StringEncoding
	}
	
	/// User agent used for downloading websites, XML documents, JSONs.
	public var infoPageUserAgent: String {
		return XUDownloadCenterDefaultUserAgent
	}
	
	/// Referer URL.
	public var refererURL: NSURL? {
		return nil
	}
	
}


/// Synchronous data loader. This class will synchronously load data from the
/// request using the session.
public class XUSynchronousDataLoader {
	
	/// Request to be loaded.
	public let request: NSURLRequest
	
	/// Session to be used for the data load.
	public let session: NSURLSession
	
	/// Designated initializer. Session defaults to NSURLSession.sharedSession().
	public init(request: NSURLRequest, andSession session: NSURLSession = NSURLSession.sharedSession()) {
		self.request = request
		self.session = session
	}
	
	/// Loads data from self.request and either throws, or returns a tuple of 
	/// NSData and NSURLResponse?. Note that the response can indeed be nil even
	/// if the data part is nonnil.
	///
	/// IMPORTANT: This method asserts that the current queue != delegateQueue of
	/// self.session, which usually is the main queue. It is important not to
	/// invoke this method in such manner since it would lead to a deadlock.
	public func loadData() throws -> (NSData, NSURLResponse?) {
		assert(NSOperationQueue.currentQueue() != self.session.delegateQueue,
		       "Can't be loading data on the same queue as is the session's delegate queue!")
		
		var data: NSData?
		var response: NSURLResponse?
		var error: NSError?
		
		let lock = NSConditionLock(condition: 0)
		
		self.session.dataTaskWithRequest(request, completionHandler: {
			data = $0.0
			response = $0.1
			error = $0.2
			
			lock.lockWhenCondition(0)
			lock.unlockWithCondition(1)
		}).resume()
		
		lock.lockWhenCondition(1)
		lock.unlockWithCondition(0)
		
		if error != nil {
			throw error!
		}
		if data == nil {
			throw NSError(domain: NSCocoaErrorDomain, code: 0, userInfo: [
				NSLocalizedFailureReasonErrorKey: XULocalizedString("Unknown error.")
			])
		}
		return (data!, response!)
	}
	
}


/// Class that handles communication over HTTP and parsing the responses.
public class XUDownloadCenter {
	
	/// Configuration of the proxy.
	public struct ProxyConfiguration {
		
		/// Type of the proxy. Currently only HTTP, HTTPS and SOCKS are supported.
		public enum ProxyType {
			
			/// Pure HTTP proxy.
			case HTTP
			
			/// HTTPS proxy. Not tested on iOS at this point. Use with caution.
			case HTTPS
			
			/// SOCKS proxy. SOCKS 4 is currently not supported, this defaults
			/// to SOCKS 5.
			case SOCKS
		}
		
		/// Structure encapsulating the host information.
		public struct Host {
			
			/// Host address - typically an IP address.
			let address: String
			
			/// Port of the host.
			let port: Int
			
			/// Designated initializer.
			public init(address: String, andPort port: Int) {
				self.address = address
				self.port = port
			}
		}
		
		/// Structure encapsulating username + password.
		public struct Credentials {
			
			/// Password.
			public let password: String
			
			/// Username.
			public let username: String
			
			/// Designated initializer.
			public init(username: String, andPassword password: String) {
				self.username = username
				self.password = password
			}
			
		}
		
		/// Optionally, credentials. Applies to SOCKS only.
		public let credentials: Credentials?
		
		/// Host of the proxy.
		public let host: Host
		
		/// Type of the proxy.
		public let proxyType: ProxyType
		
		public init(host: Host, type: ProxyType, andCredentials credentials: Credentials? = nil) {
			self.host = host
			self.proxyType = type
			self.credentials = credentials
		}
		
	}
	
	/// TODO: These should be @noescape. Depends on SR-2266.
	
	/// A closure typealias that takes fields as a parameter - this dictionary
	/// should be modified and supplied with fields to be sent in a POST request.
	public typealias POSTFieldsModifier = (fields: inout [String : String]) -> Void
	
	/// A closure typealias for modifying a NSMutableURLRequest.
	public typealias URLRequestModifier = (request: NSMutableURLRequest) -> Void
	
	@available(*, deprecated, renamed="POSTFieldsModifier")
	public typealias XUPOSTFieldsModifier = POSTFieldsModifier
	
	@available(*, deprecated, renamed="URLRequestModifier")
	public typealias XUURLRequestModifier = URLRequestModifier
	
	
	/// Returns the last error that occurred. Nil, if no error occurred yet.
	public private(set) var lastError: NSError?
	
	/// Returns the last URL response. Nil, if this download center didn't download
	/// anything yet.
	public private(set) var lastHTTPURLResponse: NSHTTPURLResponse?
	
	/// If true, logs all traffic via XULog.
	public var logTraffic: Bool = true
	
	/// Owner of the download center. Used for delegation. Must be non-nil.
	public private(set) weak var owner: XUDownloadCenterOwner!
	
	/// Proxy configuration. By default nil, set to nonnil value for proxy support.
	public var proxyConfiguration: ProxyConfiguration? {
		didSet {
			guard let config = self.proxyConfiguration else {
				self.session.configuration.connectionProxyDictionary = nil
				return
			}
			
			var dict: [String : AnyObject] = [:]
			switch config.proxyType {
			case .HTTP:
				dict[kCFStreamPropertyHTTPProxyHost as String] = config.host.address
				dict[kCFStreamPropertyHTTPProxyPort as String] = config.host.port
			case .HTTPS:
				dict[kCFStreamPropertyHTTPProxyHost as String] = config.host.address
				dict[kCFStreamPropertyHTTPProxyPort as String] = config.host.port
				
				dict[kCFStreamPropertyHTTPSProxyHost as String] = config.host.address
				dict[kCFStreamPropertyHTTPSProxyPort as String] = config.host.port
			case .SOCKS:
				dict[kCFStreamPropertySOCKSProxyHost as String] = config.host.address
				dict[kCFStreamPropertySOCKSProxyPort as String] = config.host.port
				
				if let credentials = config.credentials {
					dict[kCFStreamPropertySOCKSUser as String] = credentials.username
					dict[kCFStreamPropertySOCKSPassword as String] = credentials.password
				}
			}
			
			self.session.configuration.connectionProxyDictionary = dict
		}
	}
	
	/// Session this download center was initialized with.
	public let session: NSURLSession
	
	/// Initializer. The owner must keep itself alive as long as the download
	/// center is alive. If the owner is to be dealloc'ed, dealloc the download
	/// center as well.
	///
	/// By default the session is populated with NSURLSession.sharedSession. It 
	/// may be a good idea in many cases to create your own session instead,
	/// mostly if you are setting the proxy configurations since that modifies
	/// the session configuration which may lead to app-wide behavior changes.
	public init(owner: XUDownloadCenterOwner, session: NSURLSession = NSURLSession.sharedSession()) {
		self.owner = owner
		self.session = session
	}
	
	/// Imports cookies from response to NSHTTPCookieStorage.
	private func _importCookiesFromURLResponse(response: NSHTTPURLResponse) {
		guard let
			URL = response.URL,
			fields = response.allHeaderFields as? [String:String] else {
				return
		}
		let cookies = NSHTTPCookie.cookiesWithResponseHeaderFields(fields, forURL: URL)
		let storage = NSHTTPCookieStorage.sharedHTTPCookieStorage()
		storage.setCookies(cookies, forURL: URL, mainDocumentURL: nil)
	}
	
	/// Sets the Cookie HTTP header field on request.
	private func _setupCookieFieldForURLRequest(request: NSMutableURLRequest, andBaseURL originalBaseURL: NSURL? = nil) {
		guard let URL = request.URL else {
			return
		}
		
		let baseURL: NSURL!
		if originalBaseURL != nil {
			baseURL = originalBaseURL
		} else {
			baseURL = NSURL(scheme: URL.scheme, host: URL.host, path: "/")
			if baseURL == nil {
				return
			}
		}
		
		let storage = NSHTTPCookieStorage.sharedHTTPCookieStorage()
		guard let cookies = storage.cookiesForURL(baseURL) else {
			return
		}
		
		var cookieString = cookies.flatMap({ (obj: NSHTTPCookie) -> String? in
			return "\(obj.name)=\(obj.value)"
		}).joinWithSeparator(";")
		
		if cookieString.isEmpty {
			return // There's not point of setting the cookie field is there are no cookies
		}
		
		if let originalCookie = request.valueForHTTPHeaderField("Cookie") {
			if cookieString.characters.count == 0 {
				cookieString = originalCookie
			} else {
				cookieString = cookieString + ";\(originalCookie)"
			}
		}
		
		request.setValue(cookieString, forHTTPHeaderField: "Cookie")
	}
	
	/// Adds a cookie with name and value under URL.
	public func addCookie(value: String, forName name: String, andHost host: String) {
		let storage = NSHTTPCookieStorage.sharedHTTPCookieStorage()
		
		if let cookie = NSHTTPCookie(properties: [
			NSHTTPCookieName: name,
			NSHTTPCookieValue: value,
			NSHTTPCookiePath: "/",
			NSHTTPCookieDomain: host
		]) {
			storage.setCookie(cookie)
		}
	}
	
	/// Clears the cookie storage for a particular URL.
	public func clearCookiesForURL(URL: NSURL) {
		let storage = NSHTTPCookieStorage.sharedHTTPCookieStorage()
		guard let cookies = storage.cookiesForURL(URL) else {
			return
		}
		
		cookies.forEach({ storage.deleteCookie($0) })
	}
	
	public func downloadDataAtURL(URL: NSURL!, withReferer referer: String? = nil, asAgent agent: String? = nil, referingFunction: String = #function, withModifier modifier: URLRequestModifier? = nil) -> NSData? {
		if URL == nil {
			return nil
		}
		
		let request = NSMutableURLRequest(URL: URL, cachePolicy: .ReloadIgnoringLocalCacheData, timeoutInterval: 15.0)
		request.userAgent = agent
		request.referer = referer
		
		self._setupCookieFieldForURLRequest(request)
		
		if request.acceptType == nil {
			request.acceptType = "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8"
		}
		
		self.owner.setupURLRequest(request, forDownloadingPageAtURL: URL!)

		if modifier != nil {
			modifier!(request: request)
		}
		
		if XUDebugLog.isLoggingEnabled && self.logTraffic {
			var logString = "Method: \(request.HTTPMethod)\nHeaders: \(request.allHTTPHeaderFields ?? [ : ])"
			if request.HTTPBody != nil && request.HTTPBody!.length > 0 {
				logString += "\nHTTP Body: \(String(data: request.HTTPBody) ?? "")"
			}
			
			XULog("[\(self.owner.name)] Will be downloading URL \(URL!):\n\(logString)", method: referingFunction)
		}
		
		do {
			let (data, response) = try XUSynchronousDataLoader(request: request, andSession: self.session).loadData()
			self.lastHTTPURLResponse = response as? NSHTTPURLResponse
			return data
		} catch let error as NSError {
			self.lastHTTPURLResponse = nil
			self.lastError = error
			return nil
		}
	}
	
	/// Downloads the JSON and attempts to cast it to dictionary.
	public func downloadJSONDictionaryAtURL(URL: NSURL!, withReferer referer: String? = nil, asAgent agent: String? = nil, withModifier modifier: URLRequestModifier? = nil) -> XUJSONDictionary? {
		guard let obj = self.downloadJSONAtURL(URL, withReferer: referer, asAgent: agent, withModifier: modifier) else {
			return nil // Error already set.
		}
		
		guard let dict = obj as? XUJSONDictionary else {
			self.owner.downloadCenter(self, didEncounterError: .WrongJSONFormat)
			return nil
		}
		
		return dict
	}
	
	/// Downloads a website source, parses it as JSON and returns it.
	public func downloadJSONAtURL(URL: NSURL!, withReferer referer: String? = nil, asAgent agent: String? = nil, withModifier modifier: URLRequestModifier? = nil) -> AnyObject? {
		let data = self.downloadDataAtURL(URL, withReferer: referer, asAgent: agent) { (request) -> Void in
			request.addJSONAcceptToHeader()
			
			if modifier != nil {
				modifier!(request: request)
			}
		}
		
		if data == nil {
			self.owner.downloadCenter(self, didEncounterError: .NoInternetConnection)
			return nil
		}
		
		guard let obj = self.JSONObjectFromData(data!) else {
			return nil // Error already set by JSONObjectFromString(_:)
		}
		
		return obj
	}
	
	/// Downloads a pure website source.
	public func downloadWebSiteSourceAtURL(URL: NSURL!, withReferer referer: String? = nil, asAgent agent: String? = nil, withModifier modifier: URLRequestModifier? = nil) -> String? {
		if URL == nil {
			return nil
		}
		
		guard let data = self.downloadDataAtURL(URL, withReferer: referer, asAgent: agent, withModifier: modifier) else {
			if self.logTraffic {
				XULog("[\(self.owner.name)] - Failed to load URL connection to URL \(URL!) - \(self.lastError.descriptionWithDefaultValue("unknown error"))")
			}
			return nil
		}
		
		
		if self.logTraffic {
			XULog("[\(self.owner.name)] - downloaded web site source from \(URL!), response: \(self.lastHTTPURLResponse.descriptionWithDefaultValue())")
		}
		
		if let responseString = String(data: data, encoding: self.owner.defaultSourceEncoding) {
			return responseString
		}
		
		/* Fallback */
		return String(data: data)
	}
	
	/// Does the same as the varian without the `fields` argument, but adds or
	/// replaces some field values.
	public func downloadWebSiteSourceByPostingFormOnPage(source: String, toURL URL: NSURL!, forceSettingFields fields: [String:String]) -> String? {
		return self.downloadWebSiteSourceByPostingFormOnPage(source, toURL: URL, withModifier: { (inout inputFields: [String:String]) in
			inputFields += fields
		})
	}
	
	/// Sends a POST request to `URL` and automatically gathers <input name="..."
	/// value="..."> pairs in `source` and posts them as WWW form.
	public func downloadWebSiteSourceByPostingFormOnPage(source: String, toURL URL: NSURL!, withModifier modifier: POSTFieldsModifier? = nil) -> String? {
		var inputFields = source.allVariablePairsForRegexString("<input[^>]+name=\"(?P<VARNAME>[^\"]+)\"[^>]+value=\"(?P<VARVALUE>[^\"]*)\"")
		inputFields += source.allVariablePairsForRegexString("<input[^>]+value=\"(?P<VARVALUE>[^\"]*)\"[^>]+name=\"(?P<VARNAME>[^\"]+)\"")
		if inputFields.count == 0 {
			if self.logTraffic {
				XULog("[\(self.owner.name)] - no input fields in \(source)")
			}
			self.owner.downloadCenter(self, didEncounterError: .NoInputFields)
			return nil
		}
		
		if modifier != nil {
			modifier!(fields: &inputFields)
		}
		return self.downloadWebSiteSourceByPostingFormWithValues(inputFields, toURL: URL)
	}
	
	/// The previous methods (downloadWebSiteSourceByPostingFormOnPage(*)) eventually
	/// invoke this method that posts the specific values to URL.
	public func downloadWebSiteSourceByPostingFormWithValues(values: [String : String], toURL URL: NSURL!) -> String? {
		return self.downloadWebSiteSourceAtURL(URL, withReferer: self.owner.refererURL?.absoluteString, asAgent: self.owner.infoPageUserAgent, withModifier: { (request) in
			request.HTTPMethod = "POST"
			
			if self.logTraffic {
				XULog("[\(self.owner.name)] POST fields: \(values)")
			}
			
			let bodyString = values.URLQueryString
			request.HTTPBody = bodyString.dataUsingEncoding(NSUTF8StringEncoding)
		})
	}
	
	#if os(OSX)
	
	/// Attempts to download content at `URL` and parse it as XML.
	public func downloadXMLDocumentAtURL(URL: NSURL!, withReferer referer: String? = nil, asAgent agent: String? = nil, withModifier modifier: URLRequestModifier? = nil) -> NSXMLDocument? {
		guard let source = self.downloadWebSiteSourceAtURL(URL, withReferer: referer, asAgent: agent, withModifier: modifier) else {
			return nil // Error already set.
		}
	
		let doc = try? NSXMLDocument(XMLString: source, options: NSXMLDocumentTidyXML)
		if doc == nil {
			if self.logTraffic {
				XULog("[\(self.owner.name)] - failed to parse XML document \(source)")
			}
			self.owner.downloadCenter(self, didEncounterError: .InvalidXMLResponse)
		}
		return doc
	}
	
	#endif
	
	/// Parses the `JSONString` as JSON and attempts to cast it to XUJSONDictionary.
	public func JSONDictionaryFromString(JSONString: String!) -> XUJSONDictionary? {
		guard let obj = self.JSONObjectFromString(JSONString) else {
			return nil
		}
		
		guard let dict = obj as? XUJSONDictionary else {
			if self.logTraffic {
				XULog("String represents a valid JSON object, but isn't dictionary: \(obj.dynamicType) \(obj)")
			}
			self.owner.downloadCenter(self, didEncounterError: .WrongJSONFormat)
			return nil
		}
		return dict
	}
	
	/// Attempts to parse `data` as JSON.
	public func JSONObjectFromData(data: NSData) -> AnyObject? {
		let obj = try? NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions())
		if obj == nil {
			self.owner.downloadCenter(self, didEncounterError: .InvalidJSONResponse)
			
			if self.logTraffic {
				XULog("[\(self.owner.name)] - failed to parse JSON \(String(data: data).descriptionWithDefaultValue())")
			}
		}
		
		return obj
	}
	
	/// Attempts to parse `JSONString` as JSON.
	public func JSONObjectFromString(JSONString: String!) -> AnyObject? {
		if JSONString == nil {
			self.owner.downloadCenter(self, didEncounterError: .InvalidJSONResponse)
			
			if self.logTraffic {
				XULog("[\(self.owner.name)] - Trying to pass nil JSONString.")
			}
			return nil
		}
		
		guard let data = JSONString!.dataUsingEncoding(NSUTF8StringEncoding) else {
			self.owner.downloadCenter(self, didEncounterError: .InvalidJSONResponse)
			
			if self.logTraffic {
				XULog("[\(self.owner.name)] - Cannot get non-nil string data! \(JSONString!)")
			}
			return nil
		}
		
		return self.JSONObjectFromData(data)
	}
	
	/// Some JSON responses may contain secure prefixes - this method attempts
	/// to find the JSON potential callback function.
	public func JSONObjectFromCallbackString(JSONString: String!) -> AnyObject? {
		guard let innerJSON = JSONString?.getRegexVariableNamed("JSON", forRegexStrings: "\\((?P<JSON>.*)\\)", "/\\*-secure-\\s*(?P<JSON>{.*})", "^\\w+=(?P<JSON>{.*})") else {
			
			if self.logTraffic {
				XULog("[\(self.owner.name)] - no inner JSON in callback string \(JSONString ?? "")")
			}
			return nil
		}
		
		return self.JSONObjectFromString(innerJSON)
	}
	
	/// Returns last HTTP status code or 0.
	public var lastHTTPStatusCode: Int {
		return self.lastHTTPURLResponse?.statusCode ?? 0
	}
	
	
	/// Based on the request's URL, the Cookie field is filled with cookies from
	/// the default storage.
	public func setupCookieFieldForURLRequest(request: NSMutableURLRequest, andBaseURL baseURL: NSURL? = nil) {
		self._setupCookieFieldForURLRequest(request, andBaseURL: baseURL)
	}
	
	/// Sends a HEAD request to `URL` and returns the status code or 0.
	public func statusCodeForURL(URL: NSURL!) -> Int {
		return self.sendHeadRequestToURL(URL)?.statusCode ?? 0
	}
	
	/// Sends a HEAD request to `URL`.
	public func sendHeadRequestToURL(URL: NSURL!, withReferer referer: String? = nil, withRequestModifier modifier: URLRequestModifier? = nil) -> NSHTTPURLResponse? {
		if URL == nil {
			return nil
		}
		
		let req = NSMutableURLRequest(URL: URL!)
		req.HTTPMethod = "HEAD"
		req.referer = referer
		
		self._setupCookieFieldForURLRequest(req)
		
		if modifier != nil {
			modifier!(request: req)
		}
		
		do {
			let (_, response) = try XUSynchronousDataLoader(request: req, andSession: self.session).loadData()
			
			guard let HTTPResponse = response as? NSHTTPURLResponse else {
				if self.logTraffic {
					XULog("-[\(self)[\(self.owner.name)] \(#function)] - invalid response (non-HTTP): \(response.descriptionWithDefaultValue())")
				}
				return nil
			}
			
			if self.logTraffic {
				XULog("-[\(self)[\(self.owner.name)] \(#function)] - 'HEAD'ing \(URL!), response: \(HTTPResponse) \(HTTPResponse.allHeaderFields)")
			}
			
			self._importCookiesFromURLResponse(HTTPResponse)
			
			self.lastHTTPURLResponse = HTTPResponse
			return HTTPResponse
		}catch let error {
			if self.logTraffic {
				XULog("-[\(self)[\(self.owner.name)] \(#function)] - Failed to send HEAD to URL \(URL!) - \(error)")
			}
			return nil
		}
	}
	
}
