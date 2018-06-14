//
//  XUDownloadCenter.swift
//  XUCore
//
//  Created by Charlie Monroe on 2/23/16.
//  Copyright © 2016 Charlie Monroe Software. All rights reserved.
//

import Foundation

/// A download center observer. This allows you to observe that the download center
/// will be downloading some content. This may get further extended in the future.
/// All methods are optional as they have a default implementation.
public protocol XUDownloadCenterObserver: AnyObject {
	func downloadCenter(_ center: XUDownloadCenter, didDownloadContentFrom url: URL, response: HTTPURLResponse?, data: Data)
	func downloadCenter(_ center: XUDownloadCenter, didFailToDownloadContentFrom url: URL, error: Error?)
	func downloadCenter(_ center: XUDownloadCenter, willDownloadContentFrom url: URL)
}

extension XUDownloadCenterObserver {
	public func downloadCenter(_ center: XUDownloadCenter, didDownloadContentFrom url: URL, response: HTTPURLResponse?, data: Data) {}
	public func downloadCenter(_ center: XUDownloadCenter, didFailToDownloadContentFrom url: URL, error: Error?) {}
	public func downloadCenter(_ center: XUDownloadCenter, willDownloadContentFrom url: URL) {}
}


/// Class that handles communication over HTTP and parsing the responses.
open class XUDownloadCenter {
	
	public enum Error {
		
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
	
	/// Structure that encloses HTTP header fields and is used by XUDownloadCenter's
	/// automatic header fields.
	public struct HeaderFields: XUHTTPHeaderFields {
		
		public init() {}
		
		/// Request modifier. Can be used along with XUDownloadCenter.
		public var requestModifier: (inout URLRequest) -> Void {
			return { (request: inout URLRequest) in
				for (key, value) in self.values {
					request[key] = value
				}
			}
		}
		
		public subscript(field: String) -> String? {
			get {
				return values[field] ?? nil
			}
			set {
				self.values[field] = newValue
			}
		}
		
		/// Raw values.
		public var values: [String : String?] = [:]
		
	}
	
	
	/// A closure typealias that takes fields as a parameter - this dictionary
	/// should be modified and supplied with fields to be sent in a POST request.
	public typealias POSTFieldsModifier = (_ fields: inout [String : String]) -> Void
	
	/// A closure typealias for modifying a URLRequest.
	public typealias URLRequestModifier = (_ request: inout URLRequest) -> Void
	
	
	
	/// These values are automatically applied to all requests. This can be an
	/// authorization header field, or some other additional header fields required
	/// by the server. These are applied before the requestModifier is called.
	public final var automaticHeaderFieldValues: HeaderFields = HeaderFields()
	
	/// Default encoding used by self.downloadWebPage(at:...).
	public final var defaultStringEncoding: String.Encoding = .utf8
	
	/// Handler called when an error is encountered. This can be used for additional
	/// logging.
	public final var errorHandler: ((XUDownloadCenter.Error) -> Void)?
	
	/// Identifier identifying the download center. This value is used for logging.
	public final var identifier: String
	
	/// Returns the last error that occurred. Nil, if no error occurred yet.
	public final private(set) var lastError: Swift.Error?
	
	/// Returns the last URL response. Nil, if this download center didn't download
	/// anything yet.
	public final private(set) var lastHTTPURLResponse: HTTPURLResponse?
	
	/// If true, logs all traffic via XULog.
	public final var logTraffic: Bool = true
	
	/// Observer.
	public weak var observer: XUDownloadCenterObserver?
	
	/// Proxy configuration. By default nil, set to nonnil value for proxy support.
	/// Note that this changes self.session since NSURLSessionConfiguration won't
	/// stick the proxy unless a copy is made first.
	public final var proxyConfiguration: ProxyConfiguration? {
		didSet {
			let sessionConfig = self.session.configuration.copy() as! URLSessionConfiguration
			sessionConfig.connectionProxyDictionary = self.proxyConfiguration?.urlSessionProxyDictionary
			self.session = URLSession(configuration: sessionConfig)
		}
	}
	
	/// Session this download center was initialized with.
	public final private(set) var session: URLSession

	
	
	/// Initializer.
	///
	/// By default the session is populated with URLSession.sharedSession. It 
	/// may be a good idea in many cases to create your own session instead,
	/// mostly if you are setting the proxy configurations since that modifies
	/// the session configuration which may lead to app-wide behavior changes.
	public init(identifier: String, session: URLSession = URLSession.shared) {
		self.identifier = identifier
		self.session = session
	}
	
	
	/// Applies self.automaticHeaderFieldValues to a request.
	private func _applyAutomaticHeaderFields(to request: inout URLRequest) {
		self.automaticHeaderFieldValues.requestModifier(&request)
	}
	
	/// Imports cookies from response to NSHTTPCookieStorage.
	private func _importCookies(from response: HTTPURLResponse) {
		guard
			let url = response.url,
			let fields = response.allHeaderFields as? [String : String]
		else {
			XULog("Not importing cookies, because response.url is nil, or can't get any header fields: \(response)")
			return
		}
		
		var cookies = HTTPCookie.cookies(withResponseHeaderFields: fields, for: url)
		
		// The cookie storage will not properly save them in case they do not have
		// the expiration date.
		cookies = cookies.map({ (cookie) -> HTTPCookie in
			var properties = cookie.properties ?? [:]
			properties[.expires] = Date.distantFuture
			return HTTPCookie(properties: properties)!
		})
		
		XULog("Importing cookies for \(url): \(cookies)")
		
		let storage = HTTPCookieStorage.shared
		storage.setCookies(cookies, for: url, mainDocumentURL: nil)
	}
	
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
	public func downloadData(at url: URL!, referingFunction: String = #function, acceptType: String? = "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8", withRequestModifier modifier: URLRequestModifier? = nil) -> Data? {
		guard let url = url else {
			XULogStacktrace("Trying to download from nil URL, returning nil.")
			return nil
		}
		
		self.observer?.downloadCenter(self, willDownloadContentFrom: url)
		
		var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 15.0)
		self._setupCookieField(forRequest: &request)
		self._applyAutomaticHeaderFields(to: &request)
		
		request.acceptType = acceptType
		modifier?(&request)
		
		if XUDebugLog.isLoggingEnabled && self.logTraffic {
			var logString = "Method: \(request.httpMethod.descriptionWithDefaultValue())\nHeaders: \(request.allHTTPHeaderFields ?? [ : ])"
			if request.httpBody != nil && request.httpBody!.count > 0 {
				logString += "\nHTTP Body: \(String(data: request.httpBody) ?? "")"
			}
			
			XULog("[\(self.identifier)] Will be downloading URL \(url):\n\(logString)", method: referingFunction)
		}
		
		do {
			let (data, response) = try XUSynchronousDataLoader(request: request as URLRequest, andSession: self.session).loadData()
			self.lastHTTPURLResponse = response as? HTTPURLResponse
			
			if self.logTraffic {
				XULog("[\(self.identifier)] - downloaded web site source from \(url), response: \(self.lastHTTPURLResponse.descriptionWithDefaultValue())")
			}
			
			self.observer?.downloadCenter(self, didDownloadContentFrom: url, response: response as? HTTPURLResponse, data: data)
			
			return data
		} catch let error {
			self.lastHTTPURLResponse = nil
			self.lastError = error
			
			self.observer?.downloadCenter(self, didFailToDownloadContentFrom: url, error: error)
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
			self.errorHandler?(.noInternetConnection)
			return nil
		}
		
		guard let obj: T = XUJSONHelper.object(from: data) else {
			self.errorHandler?(.invalidJSONResponse)
			return nil
		}
		
		return obj
	}
	
	/// Downloads a pure website source. The download center will try to interpret
	/// the data with preferredEncoding. If that fails, it will fall back to any
	/// other encoding.
	public func downloadWebPage(at url: URL!, preferredEncoding: String.Encoding? = nil, withRequestModifier modifier: URLRequestModifier? = nil) -> String? {
		guard let url = url else {
			return nil
		}
		
		guard let data = self.downloadData(at: url, withRequestModifier: modifier) else {
			if self.logTraffic {
				XULog("[\(self.identifier)] - Failed to load URL connection to URL \(url) - \(self.lastError.descriptionWithDefaultValue("unknown error"))")
			}
			return nil
		}
		
		if let responseString = String(data: data, encoding: preferredEncoding ?? self.defaultStringEncoding) {
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
				XULog("[\(self.identifier)] - no input fields in \(source)")
			}
			self.errorHandler?(.noInputFields)
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
			
			if self.logTraffic {
				XULog("[\(self.self.identifier)] POST fields: \(values)")
			}
			
			let bodyString = values.urlQueryString
			request.httpBody = bodyString.data(using: .utf8)
			
			requestModifier?(&request)
		})
	}
	
	#if os(OSX)
	
	/// Attempts to download content at `URL` and parse it as XML.
	public func downloadXMLDocument(at url: URL!, withRequestModifier modifier: URLRequestModifier? = nil) -> XMLDocument? {
		guard let source = self.downloadWebPage(at: url, withRequestModifier: modifier) else {
			return nil // Error already set.
		}
	
		guard let doc = try? XMLDocument(xmlString: source, options: .documentTidyXML) else {
			if self.logTraffic {
				XULog("[\(self.identifier)] - failed to parse XML document \(source)")
			}
			self.errorHandler?(.invalidXMLResponse)
			return nil
		}
		return doc
	}
	
	#endif
	
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
		guard let url = url else {
			return nil
		}
		
		var request = URLRequest(url: url)
		request.httpMethod = "HEAD"
		
		self._setupCookieField(forRequest: &request)
		
		modifier?(&request)
		
		do {
			let (_, response) = try XUSynchronousDataLoader(request: request, andSession: self.session).loadData()
			
			guard let httpResponse = response as? HTTPURLResponse else {
				if self.logTraffic {
					XULog("-[\(self)[\(self.identifier)] \(#function)] - invalid response (non-HTTP): \(response.descriptionWithDefaultValue())")
				}
				return nil
			}
			
			if self.logTraffic {
				XULog("-[\(self)[\(self.identifier)] \(#function)] - 'HEAD'ing \(url), response: \(httpResponse) \(httpResponse.allHeaderFields)")
			}
			
			self._importCookies(from: httpResponse)
			
			self.lastHTTPURLResponse = httpResponse
			return httpResponse
		} catch let error {
			if self.logTraffic {
				XULog("-[\(self)[\(self.identifier)] \(#function)] - Failed to send HEAD to URL \(url) - \(error)")
			}
			return nil
		}
	}
	
}
