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
	
	public enum Error: Swift.Error {
		
		/// The downloaded data cannot be interpreted as string.
		case stringDecodingError
		
		/// The underlying session was already invalidated.
		case invalidated
		
		/// This error represents a state where the NSURLSession returns nil -
		/// i.e. connection timeout or no internet connection at all.
		case noInternetConnection
		
		/// This is a specific case which can be used by downloadWebSiteSourceByPostingFormOnPage(*)
		/// methods. It means that there are no input fields available in the source.
		case noInputFields
		
		/// The download center did load some data, but it cannot be parsed as JSON.
		case invalidJSONResponse
		
		#if os(macOS)
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
				if self.values["Cookie"] == .some(nil) {
					request.httpShouldHandleCookies = false
				}
				
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
	
	
	
	private let _invalidationLock: NSRecursiveLock
	
	/// These values are automatically applied to all requests. This can be an
	/// authorization header field, or some other additional header fields required
	/// by the server. These are applied before the requestModifier is called.
	public final var automaticHeaderFieldValues: HeaderFields = HeaderFields()
	
	/// Default encoding used by self.downloadWebPage(at:...).
	public final var defaultStringEncoding: String.Encoding = .utf8
	
	/// Handler called when an error is encountered. This can be used for additional
	/// logging. This is softly deprecated.
	public final var errorHandler: ((XUDownloadCenter.Error) -> Void)?
	
	/// Identifier identifying the download center. This value is used for logging.
	public final var identifier: String
	
	/// Marked true when invalidateSession() is called.
	@LockedAccessProperty
	public private(set) final var isInvalidated: Bool
	
	/// Returns the last error that occurred. Nil, if no error occurred yet.
	public final private(set) var lastError: Swift.Error?
	
	/// Returns the last URL response. Nil, if this download center didn't download
	/// anything yet.
	@LockedAccessProperty
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
		let invalidationLock = NSRecursiveLock(name: "com.charliemonroe.download.center.invalidation")
		_invalidationLock = invalidationLock
		_isInvalidated = LockedAccessProperty(wrappedValue: false, lock: invalidationLock)
		_lastHTTPURLResponse = LockedAccessProperty(wrappedValue: nil, lock: invalidationLock)
		
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
		}).joined(separator: "; ")
		
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
	public func addCookie(_ value: String, forName name: String, host: String) {
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
	public func downloadData(at url: URL, referingFunction: String = #function, acceptType: URLRequest.ContentType? = .defaultBrowser, withRequestModifier modifier: URLRequestModifier? = nil) -> Data? {
		return try? self.downloadDataThrow(at: url, referringFunction: referingFunction, acceptType: acceptType, withRequestModifier: modifier)
	}
	
	/// Downloads data from `url`, applies request modifier. `referingFunction`
	/// is for logging purposes, use it with the default value instead.
	public func downloadDataThrow(at url: URL, referringFunction: String = #function, acceptType: URLRequest.ContentType? = .defaultBrowser, withRequestModifier modifier: URLRequestModifier? = nil) throws -> Data {
		self.observer?.downloadCenter(self, willDownloadContentFrom: url)
		
		if self.isInvalidated {
			throw Error.invalidated
		}
		
		var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 15.0)
//		request.httpShouldHandleCookies = false // We're setting them manually below.
		
		self._setupCookieField(forRequest: &request)
		request.acceptType = acceptType
		
		self._applyAutomaticHeaderFields(to: &request)
		modifier?(&request)
		
		if XUDebugLog.isLoggingEnabled && self.logTraffic {
			var logString = "Method: \(request.httpMethod.descriptionWithDefaultValue())\nHeaders: \(request.allHTTPHeaderFields ?? [ : ])"
			if request.httpBody != nil && request.httpBody!.count > 0 {
				logString += "\nHTTP Body: \(request.httpBody.flatMap(String.init(data:)) ?? "")"
			}
			
			XULog("[\(self.identifier)] Will be downloading URL \(url):\n\(logString)", method: referringFunction)
		}
		
		_invalidationLock.lock()
		defer {
			_invalidationLock.unlock()
		}
		
		if self.isInvalidated {
			throw Error.invalidated
		}
		
		let loader = XUSynchronousDataLoader(request: request, session: self.session)
		
		do {
			let response = try loader.loadData()
			self.lastHTTPURLResponse = response.response as? HTTPURLResponse
			
			if self.logTraffic {
				XULog("[\(self.identifier)] - downloaded web site source from \(url), response: \(self.lastHTTPURLResponse.descriptionWithDefaultValue())")
			}
			
			self.observer?.downloadCenter(self, didDownloadContentFrom: url, response: response.response as? HTTPURLResponse, data: response.data)
			
			return response.data
		} catch {
			if self.logTraffic {
				XULog("[\(self.identifier)] - Failed to load URL connection to URL \(url) - \(error)")
			}
			
			self.lastHTTPURLResponse = nil
			self.lastError = error
			
			self.observer?.downloadCenter(self, didFailToDownloadContentFrom: url, error: error)
			throw error
		}
	}
	
	/// Downloads the JSON and attempts to cast it to dictionary.
	public func downloadJSONDictionary(at url: URL, withRequestModifier modifier: URLRequestModifier? = nil) -> XUJSONDictionary? {
		return try? self.downloadJSONThrow(ofType: XUJSONDictionary.self, at: url, withRequestModifier: modifier)
	}
	
	/// Downloads the JSON and attempts to cast it to dictionary.
	public func downloadJSONDictionaryThrow(at url: URL, withRequestModifier modifier: URLRequestModifier? = nil) throws -> XUJSONDictionary {
		return try self.downloadJSONThrow(ofType: XUJSONDictionary.self, at: url, withRequestModifier: modifier)
	}
	
	/// Downloads a website source, parses it as JSON and returns it.
	public func downloadJSON<T>(ofType type: T.Type, at url: URL, withRequestModifier modifier: URLRequestModifier? = nil) -> T? {
		return try? self.downloadJSONThrow(ofType: type, at: url, withRequestModifier: modifier)
	}
	
	/// Downloads a website source, parses it as JSON and returns it.
	public func downloadJSONThrow<T>(ofType type: T.Type, at url: URL, withRequestModifier modifier: URLRequestModifier? = nil) throws -> T {
		let data = try self.downloadDataThrow(at: url, withRequestModifier: { (request: inout URLRequest) in
			request.acceptType = URLRequest.ContentType.json
			
			modifier?(&request)
		})
		
		guard let obj: T = XUJSONHelper.object(from: data) else {
			throw Error.invalidJSONResponse
		}
		
		return obj
	}
	
	/// Downloads a pure website source. The download center will try to interpret
	/// the data with preferredEncoding. If that fails, it will fall back to any
	/// other encoding.
	public func downloadWebPage(at url: URL, preferredEncoding: String.Encoding? = nil, withRequestModifier modifier: URLRequestModifier? = nil) -> String? {
		return try? self.downloadWebPageThrow(at: url, preferredEncoding: preferredEncoding, withRequestModifier: modifier)
	}
	
	/// Downloads a pure website source. The download center will try to interpret
	/// the data with preferredEncoding. If that fails, it will fall back to any
	/// other encoding.
	public func downloadWebPageThrow(at url: URL, preferredEncoding: String.Encoding? = nil, withRequestModifier modifier: URLRequestModifier? = nil) throws -> String {
		let data = try self.downloadDataThrow(at: url, withRequestModifier: modifier)
			
		if let responseString = String(data: data, encoding: preferredEncoding ?? self.defaultStringEncoding) {
			return String(Array(responseString))
		}
		
		/* Fallback */
		guard let string = String(data: data) else {
			throw Error.stringDecodingError
		}
		
		return string
	}
	
	/// Does the same as the varian without the `fields` argument, but adds or
	/// replaces some field values.
	public func downloadWebPage(postingFormIn source: String, toURL url: URL, withAdditionalValues fields: [String : String], withRequestModifier requestModifier: URLRequestModifier? = nil) -> String? {
		return try? self.downloadWebPageThrow(postingFormIn: source, toURL: url, withAdditionalValues: fields, withRequestModifier: requestModifier)
	}
	
	/// Does the same as the varian without the `fields` argument, but adds or
	/// replaces some field values.
	public func downloadWebPageThrow(postingFormIn source: String, toURL url: URL, withAdditionalValues fields: [String : String], withRequestModifier requestModifier: URLRequestModifier? = nil) throws -> String {
		return try self.downloadWebPageThrow(postingFormIn: source, to: url, fieldsModifier: { (inputFields: inout [String : String]) in
			inputFields += fields
		}, requestModifier: requestModifier)
	}

	
	/// Sends a POST request to `URL` and automatically gathers <input name="..."
	/// value="..."> pairs in `source` and posts them as WWW form.
	public func downloadWebPage(postingFormIn source: String, toURL url: URL, withFieldsModifier modifier: POSTFieldsModifier? = nil, withRequestModifier requestModifier: URLRequestModifier? = nil) -> String? {
		return try? self.downloadWebPageThrow(postingFormIn: source, to: url, fieldsModifier: modifier, requestModifier: requestModifier)
	}
	
	/// Sends a POST request to `URL` and automatically gathers <input name="..."
	/// value="..."> pairs in `source` and posts them as WWW form.
	public func downloadWebPageThrow(postingFormIn source: String, to url: URL, fieldsModifier: POSTFieldsModifier? = nil, requestModifier: URLRequestModifier? = nil) throws -> String {
		var inputFields = source.allVariablePairs(forRegex: "<input[^>]+name=\"(?P<VARNAME>[^\"]+)\"[^>]+value=\"(?P<VARVALUE>[^\"]*)\"")
		inputFields += source.allVariablePairs(forRegex: "<input[^>]+value=\"(?P<VARVALUE>[^\"]*)\"[^>]+name=\"(?P<VARNAME>[^\"]+)\"")
		if inputFields.count == 0 {
			if self.logTraffic {
				XULog("[\(self.identifier)] - no input fields in \(source)")
			}
			throw Error.noInputFields
		}
		
		fieldsModifier?(&inputFields)
	
		return try self.downloadWebPageThrow(postingFormWithValues: inputFields, to: url, requestModifier: requestModifier)
	}
	
	/// The previous methods (downloadWebSiteSourceByPostingFormOnPage(*)) eventually
	/// invoke this method that posts the specific values to URL.
	public func downloadWebPage(postingFormWithValues values: [String : String], toURL url: URL, withRequestModifier requestModifier: URLRequestModifier? = nil) -> String? {
		return try? self.downloadWebPageThrow(postingFormWithValues: values, to: url, requestModifier: requestModifier)
	}
	
	/// The previous methods (downloadWebSiteSourceByPostingFormOnPage(*)) eventually
	/// invoke this method that posts the specific values to URL.
	public func downloadWebPageThrow(postingFormWithValues values: [String : String], to url: URL, requestModifier: URLRequestModifier? = nil) throws -> String {
		return try self.downloadWebPageThrow(at: url, withRequestModifier: { (request) in
			request.httpMethod = "POST"
			
			if self.logTraffic {
				XULog("[\(self.self.identifier)] POST fields: \(values)")
			}
			
			let bodyString = values.urlQueryString
			request.httpBody = bodyString.data(using: .utf8)
			
			requestModifier?(&request)
		})
	}
	
	#if os(macOS)
	
	/// Attempts to download content at `URL` and parse it as XML.
	public func downloadXMLDocument(at url: URL, withRequestModifier modifier: URLRequestModifier? = nil) -> XMLDocument? {
		return try? self.downloadXMLDocumentThrow(at: url, withRequestModifier: modifier)
	}
	
	/// Attempts to download content at `URL` and parse it as XML.
	public func downloadXMLDocumentThrow(at url: URL, withRequestModifier modifier: URLRequestModifier? = nil) throws -> XMLDocument {
		let source = try self.downloadWebPageThrow(at: url, withRequestModifier: modifier)
	
		do {
			return try XMLDocument(xmlString: source, options: .documentTidyXML)
		} catch {
			if self.logTraffic {
				XULog("[\(self.identifier)] - failed to parse XML document \(source)")
			}
			
			self.errorHandler?(.invalidXMLResponse)
			throw error
		}
	}
	
	#endif
	
	/// Invalidates the session (cancelling all current and future requests). Use
	/// this over calling it on the session itself as there isn't a way for the
	/// download center to know if the session is invalidated and can cause exceptions
	/// if calls have been made after the session was invalidated.
	public func invalidateSession() {
		_invalidationLock.lock()
		
		XULog("Invalidating download center \(self.identifier).")
		
		self.isInvalidated = true
		self.session.invalidateAndCancel()
		
		_invalidationLock.unlock()
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
	public func statusCode(for url: URL) -> Int {
		return self.sendHeadRequest(to: url)?.statusCode ?? 0
	}
	
	/// Sends a HEAD request to `URL`.
	public func sendHeadRequest(to url: URL, withRequestModifier modifier: URLRequestModifier? = nil) -> HTTPURLResponse? {
		if self.isInvalidated {
			return nil
		}
		
		var request = URLRequest(url: url)
		request.httpMethod = "HEAD"
		
		self._setupCookieField(forRequest: &request)
		self._applyAutomaticHeaderFields(to: &request)
		
		modifier?(&request)
		
		do {
			let response = try XUSynchronousDataLoader(request: request, session: self.session).loadData().response
			
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
