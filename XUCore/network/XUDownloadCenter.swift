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
	
	/// This error represents a state where the NSURLSession returns nil -
	/// i.e. connection timeout or no internet connection at all.
	case noInternetConnection
	
	/// This is a specific case which can be used by downloadWebSiteSourceByPostingFormOnPage(*)
	/// methods. It means that there are no input fields available in the source.
	case noInputFields
	
	/// The download center did load some data, but it cannot be parsed as JSON.
	case invalidJSONResponse
	
	#if os(OSX)
	/// The download center did load some data, but it cannot be parsed as XML.
	case invalidXMLResponse
	#endif
	
	/// The download center has downloaded and parsed the JSON, but it cannot
	/// be cast to the correct format.
	case wrongJSONFormat
	
}

/// The protocol defining the owner of the download center. Most of the conformity
/// is optional - see the extension below.
public protocol XUDownloadCenterOwner: AnyObject {
	
	/// Default encoding for web sites. UTF8 by default.
	var defaultSourceEncoding: String.Encoding { get }
	
	/// This is called whenever the download center fails to load a webpage, or
	/// parse JSON/XML.
	func downloadCenter(_ downloadCenter: XUDownloadCenter, didEncounterError error: XUDownloadCenterError)
	
	/// User agent used for downloading websites, XML documents, JSONs.
	var infoPageUserAgent: String { get }
	
	///  Name of the owner. Used for logging, etc.
	var name: String { get }
	
	/// Referer URL.
	var refererURL: URL? { get }
	
	/// Possibility to modify the request for downloading a page. No-op by default.
	func setupURLRequest(_ request: NSMutableURLRequest, forDownloadingPageAtURL pageURL: URL)
}

public extension XUDownloadCenterOwner {
	
	/// Possibility to modify the request for downloading a page. No-op by default.
	public func setupURLRequest(_ request: NSMutableURLRequest, forDownloadingPageAtURL pageURL: URL) {
		// No-op
	}
	
	/// Default encoding for web sites. UTF8 by default.
	public var defaultSourceEncoding: String.Encoding {
		return String.Encoding.utf8
	}
	
	/// User agent used for downloading websites, XML documents, JSONs.
	public var infoPageUserAgent: String {
		return XUDownloadCenterDefaultUserAgent
	}
	
	/// Referer URL.
	public var refererURL: URL? {
		return nil
	}
	
}


/// Synchronous data loader. This class will synchronously load data from the
/// request using the session.
open class XUSynchronousDataLoader {
	
	/// Request to be loaded.
	open let request: URLRequest
	
	/// Session to be used for the data load.
	open let session: URLSession
	
	/// Designated initializer. Session defaults to NSURLSession.sharedSession().
	public init(request: URLRequest, andSession session: URLSession = URLSession.shared) {
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
	open func loadData() throws -> (Data, URLResponse?) {
		assert(OperationQueue.current != self.session.delegateQueue,
		       "Can't be loading data on the same queue as is the session's delegate queue!")
		
		var data: Data?
		var response: URLResponse?
		var error: NSError?
		
		let lock = NSConditionLock(condition: 0)
		
		self.session.dataTask(with: request, completionHandler: {
			data = $0.0
			response = $0.1
			error = $0.2 as NSError?
			
			lock.lock(whenCondition: 0)
			lock.unlock(withCondition: 1)
		}).resume()
		
		lock.lock(whenCondition: 1)
		lock.unlock(withCondition: 0)
		
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
open class XUDownloadCenter {
	
	/// Configuration of the proxy.
	public struct ProxyConfiguration {
		
		/// Keys for dictionaryRepresentation and init(dictionary:)
		fileprivate struct DictionaryKeys {
			static let Host = "host"
			static let ProxyType = "proxyType"
			static let Username = "username"
		}
		
		/// Type of the proxy. Currently only HTTP, HTTPS and SOCKS are supported.
		public enum ProxyType: Int {
			
			/// Pure HTTP proxy.
			case http
			
			/// HTTPS proxy. Not tested on iOS at this point. Use with caution.
			case https
			
			/// SOCKS proxy. SOCKS 4 is currently not supported, this defaults
			/// to SOCKS 5.
			case socks
		}
		
		/// Structure encapsulating the host information.
		public struct Host {
			
			/// Keys for dictionaryRepresentation and init(dictionary:)
			fileprivate struct DictionaryKeys {
				static let Address = "address"
				static let Port = "port"
			}
			
			/// Host address - typically an IP address.
			public let address: String
			
			/// Port of the host.
			public let port: Int
			
			/// Serializes the host into a dictionary.
			public var dictionaryRepresentation: XUJSONDictionary {
				return [
					DictionaryKeys.Address: self.address as AnyObject,
					DictionaryKeys.Port: self.port as AnyObject
				]
			}
			
			/// Returns the address + port combined into "address:port".
			public var fullAddress: String {
				return "\(self.address):\(self.port)"
			}
			
			/// Designated initializer.
			public init(address: String, andPort port: Int) {
				self.address = address
				self.port = port
			}
			
			/// Initializes self using a dictionary (@see dictionaryRepresentation).
			public init?(dictionary: XUJSONDictionary) {
				guard let address = dictionary[DictionaryKeys.Address] as? String,
						let port = dictionary[DictionaryKeys.Port] as? Int else {
					return nil
				}
				
				self.init(address: address, andPort: port)
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
		
		/// Returns a dictionary representation of the proxy. Note that this
		/// does not save the credentials. To save the credentials, call 
		/// saveCredentials() which will store the password in Keychain.
		public var dictionaryRepresentation: XUJSONDictionary {
			var dict: XUJSONDictionary = [
				DictionaryKeys.Host: self.host.dictionaryRepresentation as AnyObject,
				DictionaryKeys.ProxyType: self.proxyType.rawValue as AnyObject
			]
			
			dict[DictionaryKeys.Username] = self.credentials?.username as AnyObject?
			return dict
		}
		
		public init(host: Host, type: ProxyType, andCredentials credentials: Credentials? = nil) {
			self.host = host
			self.proxyType = type
			self.credentials = credentials
		}
		
		/// Inits self with dictionary. @see dictionaryRepresentation. Note that
		/// this automatically tries to retrieve the password if the username is
		/// stored within the dictionary.
		public init?(dictionary: XUJSONDictionary) {
			guard let hostDict = dictionary[DictionaryKeys.Host] as? XUJSONDictionary,
					let host = Host(dictionary: hostDict),
					let proxyTypeValue = dictionary[DictionaryKeys.ProxyType] as? Int,
					let proxyType = ProxyType(rawValue: proxyTypeValue) else {
				return nil
			}
			
			let credentials: Credentials?
			if let username = hostDict[DictionaryKeys.Username] as? String {
				if let password = XUKeychainAccess.sharedAccess.passwordForUsername(username, inAccount: host.fullAddress) {
					credentials = Credentials(username: username, andPassword: password)
				} else {
					credentials = nil
				}
			} else {
				credentials = nil
			}
			
			self.init(host: host, type: proxyType, andCredentials: credentials)
		}
		
		/// Saves password into the Keychain. See init(dictionary:). Will be 
		/// no-op if self.credentials == nil.
		public func saveCredentials() {
			guard let credentials = self.credentials else {
				return
			}
			
			XUKeychainAccess.sharedAccess.savePassword(credentials.password, forUsername: credentials.password, inAccount: self.host.fullAddress)
		}
		
		/// Returns a dictionary to be used with
		/// NSURLSessionConfiguration.connectionProxyDictionary.
		public var URLSessionProxyDictionary: [String : AnyObject] {
			var dict: [String : AnyObject] = [:]
			switch self.proxyType {
			case .http:
				dict[kCFNetworkProxiesHTTPEnable as String] = true as AnyObject?
				dict[kCFNetworkProxiesHTTPProxy as String] = self.host.address as AnyObject?
				dict[kCFNetworkProxiesHTTPPort as String] = self.host.port as AnyObject?
			case .https:
				dict[kCFNetworkProxiesHTTPSEnable as String] = true as AnyObject?
				dict[kCFNetworkProxiesHTTPProxy as String] = self.host.address as AnyObject?
				dict[kCFNetworkProxiesHTTPSPort as String] = self.host.port as AnyObject?
			case .socks:
				dict[kCFNetworkProxiesSOCKSEnable as String] = true as AnyObject?
				dict[kCFNetworkProxiesSOCKSProxy as String] = self.host.address as AnyObject?
				dict[kCFNetworkProxiesSOCKSPort as String] = self.host.port as AnyObject?
			}
			
			if let credentials = self.credentials {
				dict[kCFProxyUsernameKey as String] = credentials.username as AnyObject?
				dict[kCFProxyPasswordKey as String] = credentials.password as AnyObject?
			}
			return dict
		}
		
	}
	
	/// TODO: These should be @noescape. Depends on SR-2266.
	
	/// A closure typealias that takes fields as a parameter - this dictionary
	/// should be modified and supplied with fields to be sent in a POST request.
	public typealias POSTFieldsModifier = (_ fields: inout [String : String]) -> Void
	
	/// A closure typealias for modifying a NSMutableURLRequest.
	public typealias URLRequestModifier = (_ request: NSMutableURLRequest) -> Void
	
	@available(*, deprecated, renamed: "POSTFieldsModifier")
	public typealias XUPOSTFieldsModifier = POSTFieldsModifier
	
	@available(*, deprecated, renamed: "URLRequestModifier")
	public typealias XUURLRequestModifier = URLRequestModifier
	
	
	/// Returns the last error that occurred. Nil, if no error occurred yet.
	open fileprivate(set) var lastError: NSError?
	
	/// Returns the last URL response. Nil, if this download center didn't download
	/// anything yet.
	open fileprivate(set) var lastHTTPURLResponse: HTTPURLResponse?
	
	/// If true, logs all traffic via XULog.
	open var logTraffic: Bool = true
	
	/// Owner of the download center. Used for delegation. Must be non-nil.
	open fileprivate(set) weak var owner: XUDownloadCenterOwner!
	
	/// Proxy configuration. By default nil, set to nonnil value for proxy support.
	/// Note that this changes self.session since NSURLSessionConfiguration won't
	/// stick the proxy unless a copy is made first.
	open var proxyConfiguration: ProxyConfiguration? {
		didSet {
			let sessionConfig = self.session.configuration.copy() as! URLSessionConfiguration
			sessionConfig.connectionProxyDictionary = self.proxyConfiguration?.URLSessionProxyDictionary
			self.session = URLSession(configuration: sessionConfig)
		}
	}
	
	/// Session this download center was initialized with.
	open fileprivate(set) var session: URLSession
	
	/// Initializer. The owner must keep itself alive as long as the download
	/// center is alive. If the owner is to be dealloc'ed, dealloc the download
	/// center as well.
	///
	/// By default the session is populated with NSURLSession.sharedSession. It 
	/// may be a good idea in many cases to create your own session instead,
	/// mostly if you are setting the proxy configurations since that modifies
	/// the session configuration which may lead to app-wide behavior changes.
	public init(owner: XUDownloadCenterOwner, session: URLSession = URLSession.shared) {
		self.owner = owner
		self.session = session
	}
	
	/// Imports cookies from response to NSHTTPCookieStorage.
	fileprivate func _importCookiesFromURLResponse(_ response: HTTPURLResponse) {
		guard let
			URL = response.url,
			let fields = response.allHeaderFields as? [String:String] else {
				return
		}
		let cookies = HTTPCookie.cookies(withResponseHeaderFields: fields, for: URL)
		let storage = HTTPCookieStorage.shared
		storage.setCookies(cookies, for: URL, mainDocumentURL: nil)
	}
	
	/// Sets the Cookie HTTP header field on request.
	fileprivate func _setupCookieFieldForURLRequest(_ request: NSMutableURLRequest, andBaseURL originalBaseURL: URL? = nil) {
		guard let URL = request.url else {
			return
		}
		
		let baseURL: Foundation.URL!
		if originalBaseURL != nil {
			baseURL = originalBaseURL
		} else {
			baseURL = NSURL(scheme: URL.scheme!, host: URL.host, path: "/") as? URL
			if baseURL == nil {
				return
			}
		}
		
		let storage = HTTPCookieStorage.shared
		guard let cookies = storage.cookies(for: baseURL) else {
			return
		}
		
		var cookieString = cookies.flatMap({ (obj: HTTPCookie) -> String? in
			return "\(obj.name)=\(obj.value)"
		}).joined(separator: ";")
		
		if cookieString.isEmpty {
			return // There's not point of setting the cookie field is there are no cookies
		}
		
		if let originalCookie = request.value(forHTTPHeaderField: "Cookie") {
			if cookieString.characters.count == 0 {
				cookieString = originalCookie
			} else {
				cookieString = cookieString + ";\(originalCookie)"
			}
		}
		
		request.setValue(cookieString, forHTTPHeaderField: "Cookie")
	}
	
	/// Adds a cookie with name and value under URL.
	open func addCookie(_ value: String, forName name: String, andHost host: String) {
		let storage = HTTPCookieStorage.shared
		
		if let cookie = HTTPCookie(properties: [
			HTTPCookiePropertyKey.name: name,
			HTTPCookiePropertyKey.value: value,
			HTTPCookiePropertyKey.path: "/",
			HTTPCookiePropertyKey.domain: host
		]) {
			storage.setCookie(cookie)
		}
	}
	
	/// Clears the cookie storage for a particular URL.
	open func clearCookiesForURL(_ URL: Foundation.URL) {
		let storage = HTTPCookieStorage.shared
		guard let cookies = storage.cookies(for: URL) else {
			return
		}
		
		cookies.forEach({ storage.deleteCookie($0) })
	}
	
	open func downloadDataAtURL(_ URL: Foundation.URL!, withReferer referer: String? = nil, asAgent agent: String? = nil, referingFunction: String = #function, withModifier modifier: URLRequestModifier? = nil) -> Data? {
		if URL == nil {
			return nil
		}
		
		let request = NSMutableURLRequest(url: URL, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 15.0)
		request.userAgent = agent
		request.referer = referer
		
		self._setupCookieFieldForURLRequest(request)
		
		if request.acceptType == nil {
			request.acceptType = "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8"
		}
		
		self.owner.setupURLRequest(request, forDownloadingPageAtURL: URL!)

		if modifier != nil {
			modifier!(request)
		}
		
		if XUDebugLog.isLoggingEnabled && self.logTraffic {
			var logString = "Method: \(request.httpMethod)\nHeaders: \(request.allHTTPHeaderFields ?? [ : ])"
			if request.httpBody != nil && request.httpBody!.count > 0 {
				logString += "\nHTTP Body: \(String(data: request.httpBody) ?? "")"
			}
			
			XULog("[\(self.owner.name)] Will be downloading URL \(URL!):\n\(logString)", method: referingFunction)
		}
		
		do {
			let (data, response) = try XUSynchronousDataLoader(request: request as URLRequest, andSession: self.session).loadData()
			self.lastHTTPURLResponse = response as? HTTPURLResponse
			return data
		} catch let error as NSError {
			self.lastHTTPURLResponse = nil
			self.lastError = error
			return nil
		}
	}
	
	/// Downloads the JSON and attempts to cast it to dictionary.
	open func downloadJSONDictionaryAtURL(_ URL: Foundation.URL!, withReferer referer: String? = nil, asAgent agent: String? = nil, withModifier modifier: URLRequestModifier? = nil) -> XUJSONDictionary? {
		guard let obj = self.downloadJSONAtURL(URL, withReferer: referer, asAgent: agent, withModifier: modifier) else {
			return nil // Error already set.
		}
		
		guard let dict = obj as? XUJSONDictionary else {
			self.owner.downloadCenter(self, didEncounterError: .wrongJSONFormat)
			return nil
		}
		
		return dict
	}
	
	/// Downloads a website source, parses it as JSON and returns it.
	open func downloadJSONAtURL(_ URL: Foundation.URL!, withReferer referer: String? = nil, asAgent agent: String? = nil, withModifier modifier: URLRequestModifier? = nil) -> AnyObject? {
		let data = self.downloadDataAtURL(URL, withReferer: referer, asAgent: agent) { (request) -> Void in
			request.acceptType = URLRequest.ContentType.JSON
			
			if modifier != nil {
				modifier!(request)
			}
		}
		
		if data == nil {
			self.owner.downloadCenter(self, didEncounterError: .noInternetConnection)
			return nil
		}
		
		guard let obj = self.JSONObjectFromData(data!) else {
			return nil // Error already set by JSONObjectFromString(_:)
		}
		
		return obj
	}
	
	/// Downloads a pure website source.
	open func downloadWebSiteSourceAtURL(_ URL: Foundation.URL!, withReferer referer: String? = nil, asAgent agent: String? = nil, withModifier modifier: URLRequestModifier? = nil) -> String? {
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
	open func downloadWebSiteSourceByPostingFormOnPage(_ source: String, toURL URL: Foundation.URL!, forceSettingFields fields: [String:String]) -> String? {
		return self.downloadWebSiteSourceByPostingFormOnPage(source, toURL: URL, withModifier: { (inputFields: inout [String:String]) in
			inputFields += fields
		})
	}
	
	/// Sends a POST request to `URL` and automatically gathers <input name="..."
	/// value="..."> pairs in `source` and posts them as WWW form.
	open func downloadWebSiteSourceByPostingFormOnPage(_ source: String, toURL URL: Foundation.URL!, withModifier modifier: POSTFieldsModifier? = nil) -> String? {
		var inputFields = source.allVariablePairsForRegexString("<input[^>]+name=\"(?P<VARNAME>[^\"]+)\"[^>]+value=\"(?P<VARVALUE>[^\"]*)\"")
		inputFields += source.allVariablePairsForRegexString("<input[^>]+value=\"(?P<VARVALUE>[^\"]*)\"[^>]+name=\"(?P<VARNAME>[^\"]+)\"")
		if inputFields.count == 0 {
			if self.logTraffic {
				XULog("[\(self.owner.name)] - no input fields in \(source)")
			}
			self.owner.downloadCenter(self, didEncounterError: .noInputFields)
			return nil
		}
		
		if modifier != nil {
			modifier!(&inputFields)
		}
		return self.downloadWebSiteSourceByPostingFormWithValues(inputFields, toURL: URL)
	}
	
	/// The previous methods (downloadWebSiteSourceByPostingFormOnPage(*)) eventually
	/// invoke this method that posts the specific values to URL.
	open func downloadWebSiteSourceByPostingFormWithValues(_ values: [String : String], toURL URL: Foundation.URL!) -> String? {
		return self.downloadWebSiteSourceAtURL(URL, withReferer: self.owner.refererURL?.absoluteString, asAgent: self.owner.infoPageUserAgent, withModifier: { (request) in
			request.httpMethod = "POST"
			
			if self.logTraffic {
				XULog("[\(self.owner.name)] POST fields: \(values)")
			}
			
			let bodyString = values.URLQueryString
			request.httpBody = bodyString.data(using: String.Encoding.utf8)
		})
	}
	
	#if os(OSX)
	
	/// Attempts to download content at `URL` and parse it as XML.
	open func downloadXMLDocumentAtURL(_ URL: Foundation.URL!, withReferer referer: String? = nil, asAgent agent: String? = nil, withModifier modifier: URLRequestModifier? = nil) -> XMLDocument? {
		guard let source = self.downloadWebSiteSourceAtURL(URL, withReferer: referer, asAgent: agent, withModifier: modifier) else {
			return nil // Error already set.
		}
	
		let doc = try? XMLDocument(xmlString: source, options: Int(XMLNode.Options.documentTidyXML.rawValue))
		if doc == nil {
			if self.logTraffic {
				XULog("[\(self.owner.name)] - failed to parse XML document \(source)")
			}
			self.owner.downloadCenter(self, didEncounterError: .invalidXMLResponse)
		}
		return doc
	}
	
	#endif
	
	/// Parses the `JSONString` as JSON and attempts to cast it to XUJSONDictionary.
	open func JSONDictionaryFromString(_ JSONString: String!) -> XUJSONDictionary? {
		guard let obj = self.JSONObjectFromString(JSONString) else {
			return nil
		}
		
		guard let dict = obj as? XUJSONDictionary else {
			if self.logTraffic {
				XULog("String represents a valid JSON object, but isn't dictionary: \(type(of: obj)) \(obj)")
			}
			self.owner.downloadCenter(self, didEncounterError: .wrongJSONFormat)
			return nil
		}
		return dict
	}
	
	/// Attempts to parse `data` as JSON.
	open func JSONObjectFromData(_ data: Data) -> AnyObject? {
		let obj = try? JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions())
		if obj == nil {
			self.owner.downloadCenter(self, didEncounterError: .invalidJSONResponse)
			
			if self.logTraffic {
				XULog("[\(self.owner.name)] - failed to parse JSON \(String(data: data).descriptionWithDefaultValue())")
			}
		}
		
		return obj as AnyObject?
	}
	
	/// Attempts to parse `JSONString` as JSON.
	open func JSONObjectFromString(_ JSONString: String!) -> AnyObject? {
		if JSONString == nil {
			self.owner.downloadCenter(self, didEncounterError: .invalidJSONResponse)
			
			if self.logTraffic {
				XULog("[\(self.owner.name)] - Trying to pass nil JSONString.")
			}
			return nil
		}
		
		guard let data = JSONString!.data(using: String.Encoding.utf8) else {
			self.owner.downloadCenter(self, didEncounterError: .invalidJSONResponse)
			
			if self.logTraffic {
				XULog("[\(self.owner.name)] - Cannot get non-nil string data! \(JSONString!)")
			}
			return nil
		}
		
		return self.JSONObjectFromData(data)
	}
	
	/// Some JSON responses may contain secure prefixes - this method attempts
	/// to find the JSON potential callback function.
	open func JSONObjectFromCallbackString(_ JSONString: String!) -> AnyObject? {
		guard let innerJSON = JSONString?.getRegexVariableNamed("JSON", forRegexStrings: "\\((?P<JSON>.*)\\)", "/\\*-secure-\\s*(?P<JSON>{.*})", "^\\w+=(?P<JSON>{.*})") else {
			
			if self.logTraffic {
				XULog("[\(self.owner.name)] - no inner JSON in callback string \(JSONString ?? "")")
			}
			return nil
		}
		
		return self.JSONObjectFromString(innerJSON)
	}
	
	/// Returns last HTTP status code or 0.
	open var lastHTTPStatusCode: Int {
		return self.lastHTTPURLResponse?.statusCode ?? 0
	}
	
	
	/// Based on the request's URL, the Cookie field is filled with cookies from
	/// the default storage.
	open func setupCookieFieldForURLRequest(_ request: NSMutableURLRequest, andBaseURL baseURL: URL? = nil) {
		self._setupCookieFieldForURLRequest(request, andBaseURL: baseURL)
	}
	
	/// Sends a HEAD request to `URL` and returns the status code or 0.
	open func statusCodeForURL(_ URL: Foundation.URL!) -> Int {
		return self.sendHeadRequestToURL(URL)?.statusCode ?? 0
	}
	
	/// Sends a HEAD request to `URL`.
	open func sendHeadRequestToURL(_ URL: Foundation.URL!, withReferer referer: String? = nil, withRequestModifier modifier: URLRequestModifier? = nil) -> HTTPURLResponse? {
		if URL == nil {
			return nil
		}
		
		let req = NSMutableURLRequest(url: URL!)
		req.httpMethod = "HEAD"
		req.referer = referer
		
		self._setupCookieFieldForURLRequest(req)
		
		if modifier != nil {
			modifier!(req)
		}
		
		do {
			let (_, response) = try XUSynchronousDataLoader(request: req as URLRequest, andSession: self.session).loadData()
			
			guard let HTTPResponse = response as? HTTPURLResponse else {
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
