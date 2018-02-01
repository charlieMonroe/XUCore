//
//  XUDownloadCenter.swift
//  XUCore
//
//  Created by Charlie Monroe on 2/23/16.
//  Copyright © 2016 Charlie Monroe Software. All rights reserved.
//

import Foundation

@available(*, deprecated, renamed: "URLRequest.UserAgent.default")
public let XUDownloadCenterDefaultUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12) AppleWebKit/602.1.50 (KHTML, like Gecko) Version/10.0 Safari/602.1.50"

@available(*, deprecated, renamed: "URLRequest.UserAgent.defaultMobile")
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
	var infoPageUserAgent: URLRequest.UserAgent { get }
	
	///  Name of the owner. Used for logging, etc.
	var name: String { get }
	
	/// Referer URL.
	var refererURL: URL? { get }
	
	/// Possibility to modify the request for downloading a page. No-op by default.
	func setupURLRequest(_ request: inout URLRequest, forDownloadingPageAtURL pageURL: URL)
}

public extension XUDownloadCenterOwner {
	
	/// Possibility to modify the request for downloading a page. No-op by default.
	public func setupURLRequest(_ request: inout URLRequest, forDownloadingPageAtURL pageURL: URL) {
		// No-op
	}
	
	/// Default encoding for web sites. UTF8 by default.
	public var defaultSourceEncoding: String.Encoding {
		return String.Encoding.utf8
	}
	
	/// User agent used for downloading websites, XML documents, JSONs.
	public var infoPageUserAgent: URLRequest.UserAgent {
		return .default
	}
	
	/// Referer URL.
	public var refererURL: URL? {
		return nil
	}
	
}


/// Synchronous data loader. This class will synchronously load data from the
/// request using the session.
public final class XUSynchronousDataLoader {
	
	/// Request to be loaded.
	public let request: URLRequest
	
	/// Session to be used for the data load.
	public let session: URLSession
	
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
	public func loadData() throws -> (data: Data, response: URLResponse?) {
		assert(OperationQueue.current != self.session.delegateQueue,
		       "Can't be loading data on the same queue as is the session's delegate queue!")
		
		var data: Data?
		var response: URLResponse?
		var error: Error?
		
		let lock = NSConditionLock(condition: 0)
		
		self.session.dataTask(with: self.request, completionHandler: {
			data = $0
			response = $1
			error = $2
			
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
		private struct DictionaryKeys {
			static let Host = "host"
			static let ProxyType = "proxyType"
			static let Username = "username"
		}
		
		/// Type of the proxy. Currently only HTTP, HTTPS and SOCKS are supported.
		/// iOS supports only HTTP.
		public enum ProxyType: Int {
			
			/// Pure HTTP proxy.
			case http
			
			#if os(OSX)
			/// HTTPS proxy. Not tested on iOS at this point. Use with caution.
			case https
			
			/// SOCKS proxy. SOCKS 4 is currently not supported, this defaults
			/// to SOCKS 5.
			case socks
			#endif
		}
		
		/// Structure encapsulating the host information.
		public struct Host {
			
			/// Keys for dictionaryRepresentation and init(dictionary:)
			private struct DictionaryKeys {
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
					DictionaryKeys.Address: self.address,
					DictionaryKeys.Port: self.port
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
				DictionaryKeys.Host: self.host.dictionaryRepresentation,
				DictionaryKeys.ProxyType: self.proxyType.rawValue
			]
			
			dict[DictionaryKeys.Username] = self.credentials?.username
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
				if let password = XUKeychainAccess.sharedAccess.password(forUsername: username, inAccount: host.fullAddress) {
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
			
			XUKeychainAccess.sharedAccess.save(password: credentials.password, forUsername: credentials.password, inAccount: self.host.fullAddress)
		}
		
		/// Returns a dictionary to be used with
		/// NSURLSessionConfiguration.connectionProxyDictionary.
		public var urlSessionProxyDictionary: [String : Any] {
			var dict: [String : Any] = [:]
			#if os(OSX)
				switch self.proxyType {
				case .http:
					dict[kCFNetworkProxiesHTTPEnable as String] = true
					dict[kCFNetworkProxiesHTTPProxy as String] = self.host.address
					dict[kCFNetworkProxiesHTTPPort as String] = self.host.port
				case .https:
					dict[kCFNetworkProxiesHTTPEnable as String] = true
					dict[kCFNetworkProxiesHTTPProxy as String] = self.host.address
					dict[kCFNetworkProxiesHTTPPort as String] = self.host.port

					dict[kCFNetworkProxiesHTTPSEnable as String] = true
					dict[kCFNetworkProxiesHTTPSProxy as String] = self.host.address
					dict[kCFNetworkProxiesHTTPSPort as String] = self.host.port
				case .socks:
					dict[kCFNetworkProxiesSOCKSEnable as String] = true
					dict[kCFNetworkProxiesSOCKSProxy as String] = self.host.address
					dict[kCFNetworkProxiesSOCKSPort as String] = self.host.port
				}
			#else
				switch self.proxyType {
				case .http:
					dict[kCFNetworkProxiesHTTPEnable as String] = true
					dict[kCFNetworkProxiesHTTPProxy as String] = self.host.address
					dict[kCFNetworkProxiesHTTPPort as String] = self.host.port
				}
			#endif
			
			if let credentials = self.credentials {
				dict[kCFProxyUsernameKey as String] = credentials.username
				dict[kCFProxyPasswordKey as String] = credentials.password
			}
			return dict
		}
		
	}
	
	/// A closure typealias that takes fields as a parameter - this dictionary
	/// should be modified and supplied with fields to be sent in a POST request.
	public typealias POSTFieldsModifier = (_ fields: inout [String : String]) -> Void
	
	/// A closure typealias for modifying a URLRequest.
	public typealias URLRequestModifier = (_ request: inout URLRequest) -> Void
	
	
	/// Returns the last error that occurred. Nil, if no error occurred yet.
	open private(set) var lastError: Error?
	
	/// Returns the last URL response. Nil, if this download center didn't download
	/// anything yet.
	open private(set) var lastHTTPURLResponse: HTTPURLResponse?
	
	/// If true, logs all traffic via XULog.
	open var logTraffic: Bool = true
	
	/// Owner of the download center. Used for delegation. Must be non-nil.
	open private(set) weak var owner: XUDownloadCenterOwner?
	
	/// Proxy configuration. By default nil, set to nonnil value for proxy support.
	/// Note that this changes self.session since NSURLSessionConfiguration won't
	/// stick the proxy unless a copy is made first.
	open var proxyConfiguration: ProxyConfiguration? {
		didSet {
			let sessionConfig = self.session.configuration.copy() as! URLSessionConfiguration
			sessionConfig.connectionProxyDictionary = self.proxyConfiguration?.urlSessionProxyDictionary
			self.session = URLSession(configuration: sessionConfig)
		}
	}
	
	/// Session this download center was initialized with.
	open private(set) var session: URLSession
	
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
	private func _importCookies(from response: HTTPURLResponse) {
		guard let
			url = response.url,
			let fields = response.allHeaderFields as? [String:String] else {
				
				XULog("Not importing cookies, because response.url is nil, or can't get any header fields: \(response)")
				return
		}
		
		let cookies = HTTPCookie.cookies(withResponseHeaderFields: fields, for: url)
		
		XULog("Importing cookies for \(url): \(cookies)")
		
		let storage = HTTPCookieStorage.shared
		storage.setCookies(cookies, for: url, mainDocumentURL: nil)
	}
	
	/// We cache the name as the owner is weak-references.
	private lazy var _ownerName: String = self.owner?.name ?? "<<deallocated>>"
	
	/// Sets the Cookie HTTP header field on request.
	private func _setupCookieField(forRequest request: inout URLRequest, withBaseURL originalBaseURL: URL? = nil) {
		guard let url = request.url, url.scheme != nil else {
			return
		}
		
		let host = url.host ?? "nil"
		
		let baseURL: URL!
		if originalBaseURL != nil {
			baseURL = originalBaseURL
		} else {
			var components = URLComponents()
			components.scheme = url.scheme
			components.host = url.host
			components.path = "/"
			baseURL = components.url
			if baseURL == nil {
				XULog("Not setting cookies, because can't determine baseURL: \(host)")
				return
			}
		}
		
		let storage = HTTPCookieStorage.shared
		guard let cookies = storage.cookies(for: baseURL) else {
			XULog("Not setting cookies, because there are no cookies for: \(host)")
			return
		}
		
		var cookieString = cookies.compactMap({ (obj: HTTPCookie) -> String? in
			return "\(obj.name)=\(obj.value)"
		}).joined(separator: ";")
		
		if cookieString.isEmpty {
			XULog("Not setting cookies, because there are no cookies for: \(host)")
			return // There's not point of setting the cookie field is there are no cookies
		}
		
		if let originalCookie = request.value(forHTTPHeaderField: "Cookie") {
			cookieString = cookieString + ";\(originalCookie)"
		}
		
		XULog("Setting cookies for: \(host) - \(cookieString)")
		
		request.setValue(cookieString, forHTTPHeaderField: "Cookie")
	}
	
	/// Adds a cookie with name and value under URL.
	public func addCookie(_ value: String, forName name: String, andHost host: String) {
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
	public func clearCookies(for url: URL) {
		let storage = HTTPCookieStorage.shared
		guard let cookies = storage.cookies(for: url) else {
			return
		}
		
		cookies.forEach({ storage.deleteCookie($0) })
	}
	
	
	/// Downloads data from `url`, applies request modifier. `referingFunction`
	/// is for logging purposes, use it with the default value instead.
	public func downloadData(at url: URL!, referingFunction: String = #function, withRequestModifier modifier: URLRequestModifier? = nil) -> Data? {
		if url == nil {
			XULogStacktrace("Trying to download from nil URL, returning nil.")
			return nil
		}
		
		var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 15.0)
		
		self._setupCookieField(forRequest: &request)
		
		if request.acceptType == nil {
			request.acceptType = "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8"
		}
		
		self.owner?.setupURLRequest(&request, forDownloadingPageAtURL: url!)

		modifier?(&request)
		
		if XUDebugLog.isLoggingEnabled && self.logTraffic {
			var logString = "Method: \(request.httpMethod.descriptionWithDefaultValue())\nHeaders: \(request.allHTTPHeaderFields ?? [ : ])"
			if request.httpBody != nil && request.httpBody!.count > 0 {
				logString += "\nHTTP Body: \(String(data: request.httpBody) ?? "")"
			}
			
			XULog("[\(_ownerName)] Will be downloading URL \(url!):\n\(logString)", method: referingFunction)
		}
		
		do {
			let (data, response) = try XUSynchronousDataLoader(request: request as URLRequest, andSession: self.session).loadData()
			self.lastHTTPURLResponse = response as? HTTPURLResponse
			
			if self.logTraffic {
				XULog("[\(_ownerName)] - downloaded web site source from \(url!), response: \(self.lastHTTPURLResponse.descriptionWithDefaultValue())")
			}
			
			return data
		} catch let error {
			self.lastHTTPURLResponse = nil
			self.lastError = error
			return nil
		}
	}
	
	/// Downloads the JSON and attempts to cast it to dictionary.
	public func downloadJSONDictionary(at url: URL!, withRequestModifier modifier: URLRequestModifier? = nil) -> XUJSONDictionary? {
		return self.downloadJSON(at: url, withRequestModifier: modifier)
	}
	
	/// Downloads a website source, parses it as JSON and returns it.
	public func downloadJSON<T>(at url: URL!, withRequestModifier modifier: URLRequestModifier? = nil) -> T? {
		guard let data = self.downloadData(at: url, withRequestModifier: { (request: inout URLRequest) in
			request.acceptType = URLRequest.ContentType.json
			
			modifier?(&request)
		}) else {
			self.owner?.downloadCenter(self, didEncounterError: .noInternetConnection)
			return nil
		}
		
		guard let obj: T = XUJSONHelper.object(from: data) else {
			self.owner?.downloadCenter(self, didEncounterError: .invalidJSONResponse)
			return nil
		}
		
		return obj
	}
	
	/// Downloads a pure website source.
	public func downloadWebPage(at url: URL!, withRequestModifier modifier: URLRequestModifier? = nil) -> String? {
		if url == nil {
			return nil
		}
		
		guard let data = self.downloadData(at: url, withRequestModifier: modifier) else {
			if self.logTraffic {
				XULog("[\(_ownerName)] - Failed to load URL connection to URL \(url!) - \(self.lastError.descriptionWithDefaultValue("unknown error"))")
			}
			return nil
		}
		
		if let responseString = String(data: data, encoding: self.owner?.defaultSourceEncoding ?? .utf8) {
			return responseString
		}
		
		/* Fallback */
		return String(data: data)
	}
	
	/// Does the same as the varian without the `fields` argument, but adds or
	/// replaces some field values.
	public func downloadWebPage(postingFormIn source: String, toURL url: URL!, withAdditionalValues fields: [String : String], withRequestModifier requestModifier: URLRequestModifier? = nil) -> String? {
		return self.downloadWebPage(postingFormIn: source, toURL: url, withFieldsModifier: { (inputFields: inout [String : String]) in
			inputFields += fields
		}, withRequestModifier: requestModifier)
	}
	
	/// Sends a POST request to `URL` and automatically gathers <input name="..."
	/// value="..."> pairs in `source` and posts them as WWW form.
	public func downloadWebPage(postingFormIn source: String, toURL url: URL!, withFieldsModifier modifier: POSTFieldsModifier? = nil, withRequestModifier requestModifier: URLRequestModifier? = nil) -> String? {
		var inputFields = source.allVariablePairs(forRegex: "<input[^>]+name=\"(?P<VARNAME>[^\"]+)\"[^>]+value=\"(?P<VARVALUE>[^\"]*)\"")
		inputFields += source.allVariablePairs(forRegex: "<input[^>]+value=\"(?P<VARVALUE>[^\"]*)\"[^>]+name=\"(?P<VARNAME>[^\"]+)\"")
		if inputFields.count == 0 {
			if self.logTraffic {
				XULog("[\(_ownerName)] - no input fields in \(source)")
			}
			self.owner?.downloadCenter(self, didEncounterError: .noInputFields)
			return nil
		}
		
		if modifier != nil {
			modifier!(&inputFields)
		}
		return self.downloadWebPage(postingFormWithValues: inputFields, toURL: url, withRequestModifier: requestModifier)
	}
	
	/// The previous methods (downloadWebSiteSourceByPostingFormOnPage(*)) eventually
	/// invoke this method that posts the specific values to URL.
	public func downloadWebPage(postingFormWithValues values: [String : String], toURL url: URL!, withRequestModifier requestModifier: URLRequestModifier? = nil) -> String? {
		return self.downloadWebPage(at: url, withRequestModifier: { (request) in
			request.httpMethod = "POST"
			request.referer = self.owner?.refererURL?.absoluteString
			request.userAgent = self.owner?.infoPageUserAgent
			
			if self.logTraffic {
				XULog("[\(self._ownerName)] POST fields: \(values)")
			}
			
			let bodyString = values.urlQueryString
			request.httpBody = bodyString.data(using: String.Encoding.utf8)
			
			requestModifier?(&request)
		})
	}
	
	#if os(OSX)
	
	/// Attempts to download content at `URL` and parse it as XML.
	public func downloadXMLDocument(at url: URL!, withRequestModifier modifier: URLRequestModifier? = nil) -> XMLDocument? {
		guard let source = self.downloadWebPage(at: url, withRequestModifier: modifier) else {
			return nil // Error already set.
		}
	
		let doc = try? XMLDocument(xmlString: source, options: .documentTidyXML)
		if doc == nil {
			if self.logTraffic {
				XULog("[\(_ownerName)] - failed to parse XML document \(source)")
			}
			self.owner?.downloadCenter(self, didEncounterError: .invalidXMLResponse)
		}
		return doc
	}
	
	#endif
	
	/// Parses the `JSONString` as JSON and attempts to cast it to XUJSONDictionary.
	@available(*, deprecated, message: "Use XUJSONHelper")
	public func jsonDictionary(from jsonString: String!) -> XUJSONDictionary? {
		guard let obj = self.jsonObject(from: jsonString) else {
			return nil
		}
		
		guard let dict = obj as? XUJSONDictionary else {
			if self.logTraffic {
				XULog("String represents a valid JSON object, but isn't dictionary: \(type(of: obj)) \(obj)")
			}
			self.owner?.downloadCenter(self, didEncounterError: .wrongJSONFormat)
			return nil
		}
		return dict
	}
	
	/// Attempts to parse `data` as JSON.
	@available(*, deprecated, message: "Use XUJSONHelper")
	public func jsonObject(from data: Data) -> Any? {
		guard let obj = try? JSONSerialization.jsonObject(with: data, options: []) else {
			self.owner?.downloadCenter(self, didEncounterError: .invalidJSONResponse)
			
			if self.logTraffic {
				XULog("[\(_ownerName)] - failed to parse JSON \(String(data: data).descriptionWithDefaultValue())")
			}
			return nil
		}
		
		return obj
	}
	
	/// Attempts to parse `JSONString` as JSON.
	@available(*, deprecated, message: "Use XUJSONHelper")
	public func jsonObject(from jsonString: String!) -> Any? {
		if jsonString == nil {
			self.owner?.downloadCenter(self, didEncounterError: .invalidJSONResponse)
			
			if self.logTraffic {
				XULog("[\(_ownerName)] - Trying to pass nil JSONString.")
			}
			return nil
		}
		
		guard let data = jsonString!.data(using: String.Encoding.utf8) else {
			self.owner?.downloadCenter(self, didEncounterError: .invalidJSONResponse)
			
			if self.logTraffic {
				XULog("[\(_ownerName)] - Cannot get non-nil string data! \(jsonString!)")
			}
			return nil
		}
		
		return self.jsonObject(from: data)
	}
	
	/// Some JSON responses may contain secure prefixes - this method attempts
	/// to find the JSON potential callback function.
	@available(*, deprecated, message: "Use XUJSONHelper")
	public func jsonObject(fromCallback jsonString: String!) -> Any? {
		guard let innerJSON = jsonString?.value(of: "JSON", inRegexes: "^([\\w\\.\\$]+)?\\((?P<JSON>.*)\\)", "/\\*-secure-\\s*(?P<JSON>{.*})", "^\\w+=(?P<JSON>{.*})") else {
			if jsonString.first == Character("{") && jsonString.last == Character("}") {
				return self.jsonObject(from: jsonString)
			}
			
			self.owner?.downloadCenter(self, didEncounterError: .invalidJSONResponse)
			
			if self.logTraffic {
				XULog("[\(_ownerName)] - no inner JSON in callback string \(jsonString ?? "")")
			}
			return nil
		}
		
		return self.jsonObject(from: innerJSON)
	}
	
	/// Returns last HTTP status code or 0.
	public var lastHTTPStatusCode: Int {
		return self.lastHTTPURLResponse?.statusCode ?? 0
	}
	
	
	/// Based on the request's URL, the Cookie field is filled with cookies from
	/// the default storage.
	public func setupCookieField(forRequest request: inout URLRequest, withBaseURL baseURL: URL? = nil) {
		self._setupCookieField(forRequest: &request, withBaseURL: baseURL)
	}
	
	/// Sends a HEAD request to `URL` and returns the status code or 0.
	public func statusCode(for url: URL!) -> Int {
		return self.sendHeadRequest(to: url)?.statusCode ?? 0
	}
	
	/// Sends a HEAD request to `URL`.
	public func sendHeadRequest(to url: URL!, withRequestModifier modifier: URLRequestModifier? = nil) -> HTTPURLResponse? {
		if url == nil {
			return nil
		}
		
		var req = URLRequest(url: url!)
		req.httpMethod = "HEAD"
		
		self._setupCookieField(forRequest: &req)
		
		modifier?(&req)
		
		do {
			let (_, response) = try XUSynchronousDataLoader(request: req, andSession: self.session).loadData()
			
			guard let httpResponse = response as? HTTPURLResponse else {
				if self.logTraffic {
					XULog("-[\(self)[\(_ownerName)] \(#function)] - invalid response (non-HTTP): \(response.descriptionWithDefaultValue())")
				}
				return nil
			}
			
			if self.logTraffic {
				XULog("-[\(self)[\(_ownerName)] \(#function)] - 'HEAD'ing \(url!), response: \(httpResponse) \(httpResponse.allHeaderFields)")
			}
			
			self._importCookies(from: httpResponse)
			
			self.lastHTTPURLResponse = httpResponse
			return httpResponse
		} catch let error {
			if self.logTraffic {
				XULog("-[\(self)[\(_ownerName)] \(#function)] - Failed to send HEAD to URL \(url!) - \(error)")
			}
			return nil
		}
	}
	
}
