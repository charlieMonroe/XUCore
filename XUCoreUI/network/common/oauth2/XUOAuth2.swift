//
//  XUOAuth2.swift
//  XUCore
//
//  Created by Charlie Monroe on 6/21/16.
//  Copyright © 2016 Charlie Monroe Software. All rights reserved.
//

import Foundation
import XUCore

#if os(iOS)
	import UIKit // For UIViewContoller
#endif

public final class XUOAuth2Configuration {
	
	/// Payload format - by default, wwwForm is used, but if set to JSON, the payload
	/// for the token renewal is sent as JSON.
	public enum PayloadFormat: String {
		/// WWW form.
		case wwwForm
		
		/// JSON body.
		case json
		
		/// The payload is set as URL query.
		case urlQuery
	}
	
	private struct ConfigurationKeys {
		static let additionalHTTPHeaders = "additionalHTTPHeaders"
		static let authorizationBaseURLStringKey = "authorizationBaseURLString"
		static let clientIDKey = "clientID"
		static let customRedirectionURLKey = "redirectionURL"
		static let nameKey = "name"
		static let payloadFormatKey = "payloadFormat"
		static let redirectionSchemeKey = "redirectionScheme"
		static let scope = "scope"
		static let secretKey = "secret"
		static let tokenEndpointURLStringKey = "tokenEndpointURLString"
		static let tokenNeverExpiresKey = "tokenNeverExpires"
	}
	
	/// Additional HTTP headers to be passed to the token authorization.
	public var additionalHTTPHeaders: [String : String] = [:]
	
	/// URL used for authorization. This must be the base URL with no query.
	/// Passing a URL that includes a GET query in the URL will trigger an 
	/// assertion failure in the initializer.
	public let authorizationBaseURL: URL
	
	/// Authorization URL put together from authorizationBaseURL, redirectionScheme,
	/// and clientID.
	public var authorizationURL: URL {
		var queryDict = self.authorizationBaseURL.queryDictionary
		queryDict += [
			"client_id": self.clientID,
			"response_type": "code",
			"redirect_uri": self.redirectionURLString
		]
		
		queryDict["scope"] = self.scope
		
		return self.authorizationBaseURL.updatingQuery(to: queryDict)
	}
	
	/// ID of the client.
	public let clientID: String
	
	/// Custom redirection URL - this can be an HTTP request which then redirects
	/// back into the app.
	public let customRedirectionURL: URL?
	
	/// Name of the client. Used for saving the accounts, etc. It should be unique
	/// as initing two clients with the same name will cause fatalError.
	public let name: String
	
	/// Payload format - by default, wwwForm is used, but if set to JSON, the payload
	/// for the token renewal is sent as JSON.
	public let payloadFormat: PayloadFormat
	
	/// URL scheme that the app must be capable of opening. This is used for
	/// redirection within the WebView displayed.
	public let redirectionScheme: String
	
	/// The redirection URL passed to the OAuth2 authority.
	public var redirectionURLString: String {
		if let url = self.customRedirectionURL {
			return url.absoluteString
		}
		
		return "\(self.redirectionScheme)://approve"
	}
	
	/// Optional scope.
	public let scope: String?
	
	/// Client secret.
	public let secret: String
	
	/// URL for token.
	public let tokenEndpointURL: URL
	
	/// Some clients can have tokens that never expire. In such cases, the response
	/// doesn't contain refresh token, or expiration date.
	public let tokenNeverExpires: Bool
	
	public var dictionaryRepresentation: [String : Any] {
		var dict: [String : Any] = [
			ConfigurationKeys.additionalHTTPHeaders: self.additionalHTTPHeaders,
			ConfigurationKeys.authorizationBaseURLStringKey: self.authorizationBaseURL.absoluteString,
			ConfigurationKeys.clientIDKey: self.clientID,
			ConfigurationKeys.nameKey: self.name,
			ConfigurationKeys.payloadFormatKey: self.payloadFormat.rawValue,
			ConfigurationKeys.redirectionSchemeKey: self.redirectionScheme,
			ConfigurationKeys.secretKey: self.secret,
			ConfigurationKeys.tokenEndpointURLStringKey: self.tokenEndpointURL.absoluteString,
			ConfigurationKeys.tokenNeverExpiresKey: self.tokenNeverExpires
		]
		
		dict[ConfigurationKeys.scope] = self.scope
		dict[ConfigurationKeys.customRedirectionURLKey] = self.customRedirectionURL?.absoluteString
		
		return dict
	}
	
	/// Designated initializer.
	public init(authorizationBaseURL: URL, clientID: String, name: String, redirectionScheme: String, customRedirectionURL: URL? = nil, secret: String, tokenEndpointURL: URL, payloadFormat: PayloadFormat = .wwwForm, scope: String? = nil, tokenNeverExpires: Bool = false) {
		self.authorizationBaseURL = authorizationBaseURL
		self.clientID = clientID
		self.customRedirectionURL = customRedirectionURL
		self.name = name
		self.payloadFormat = payloadFormat
		self.redirectionScheme = redirectionScheme
		self.secret = secret
		self.scope = scope
		self.tokenEndpointURL = tokenEndpointURL
		self.tokenNeverExpires = tokenNeverExpires
	}
	
	public convenience init?(dictionary dict: [String : Any]) {
		guard
			let authorizationBaseURLString = dict[ConfigurationKeys.authorizationBaseURLStringKey] as? String,
			let clientID = dict[ConfigurationKeys.clientIDKey] as? String,
			let name = dict[ConfigurationKeys.nameKey] as? String,
			let redirectionScheme = dict[ConfigurationKeys.redirectionSchemeKey] as? String,
			let secret = dict[ConfigurationKeys.secretKey] as? String,
			let tokenEndpointURLString = dict[ConfigurationKeys.tokenEndpointURLStringKey] as? String
		else {
			return nil
		}
		
		guard let authorizationBaseURL = URL(string: authorizationBaseURLString), let tokenEndpointURL = URL(string: tokenEndpointURLString) else {
			return nil
		}
		
		self.init(authorizationBaseURL: authorizationBaseURL, clientID: clientID,
		          name: name, redirectionScheme: redirectionScheme,
				  customRedirectionURL: (dict[ConfigurationKeys.customRedirectionURLKey] as? String).flatMap(URL.init(_:)),
		          secret: secret, tokenEndpointURL: tokenEndpointURL,
				  payloadFormat: (dict[ConfigurationKeys.payloadFormatKey] as? String).flatMap(PayloadFormat.init(rawValue:)) ?? .wwwForm,
				  scope: dict[ConfigurationKeys.scope] as? String,
		          tokenNeverExpires: dict.boolean(forKey: ConfigurationKeys.tokenNeverExpiresKey))
		
		if let additionalHeaders = dict[ConfigurationKeys.additionalHTTPHeaders] as? [String : String] {
			self.additionalHTTPHeaders += additionalHeaders
		}
	}
	
}

public let XUOAuth2ClientErrorDomain = "XUOAuth2ClientErrorDomain"

public enum XUOAuth2ClientError: Int {
	
	/// This error happens when the user grants authorization to the app in the
	/// window, the app receives a redirection with a valid code, but then, loading
	/// the authorization response fails, or the response contains no access token.
	case invalidAuthorizationResponse
	
	/// The redirection URL is invalid. This is usually because it's missing the
	/// code in the query part of the URL.
	case invalidRedirectionURL
	
	/// This error happens when the user grants authorization to the app in the
	/// window, the app receives a redirection with a valid code, loads the 
	/// authorization response, but it specifies a different type of the token
	/// other than "bearer".
	case invalidTokenType
	
	/// User when the user deliberately closes the authorization window before 
	/// it's done with the authorization.
	case userCancelled
	
	/// Converts self into NSError.
	public var error: NSError {
		let errorString: String
		
		switch self {
		case .invalidTokenType:
			errorString = Localized("Server responded with unknown token type.", in: .core)
		case .invalidAuthorizationResponse:
			errorString = Localized("Server provided invalid authorization response.", in: .core)
		case .invalidRedirectionURL:
			errorString = Localized("Server has redirected with invalid URL.", in: .core)
		case .userCancelled:
			errorString = Localized("User cancelled the authorization.", in: .core)
		}
		
		return NSError(domain: XUOAuth2ClientErrorDomain, code: self.rawValue, userInfo: [
			NSLocalizedFailureReasonErrorKey: errorString
		])
	}
	
}


private extension XUPreferences {
	
	var oAuth2ClientDictionaries: [XUJSONDictionary]? {
		get {
			return self.value(for: .oAuth2Accounts)
		}
		nonmutating set {
			self.set(value: newValue, forKey: .oAuth2Accounts)
		}
	}
	
}

private extension XUPreferences.Key {
	static let oAuth2Accounts = XUPreferences.Key(rawValue: "XUOAuth2Accounts")
}

public final class XUOAuth2Client {
	
	/// A particular account.
	public final class Account: XUPointerEquatable, XUDownloadCenterObserver {
		
		private struct AccountKeys {
			static let identifierKey: String = "identifier"
			static let tokenExpirationDateKey: String = "tokenExpirationDate"
		}
		
		
		/// Authentication token.
		public private(set) var accessToken: String {
			didSet {
				self.save()
			}
		}
		
		/// Client this account belongs to.
		public private(set) weak var client: XUOAuth2Client!
		
		/// Download center for this particular account. The account automatically
		/// sets the authorization token and automatically renews the token when
		/// you use this download center.
		public private(set) lazy var downloadCenter: XUDownloadCenter = {
			let center = XUDownloadCenter(identifier: "OAuth2 - \(self.identifier) - \(self.client.configuration.name)")
			
			for (key, value) in self.client.configuration.additionalHTTPHeaders {
				center.automaticHeaderFieldValues[key] = value
			}
			center.automaticHeaderFieldValues["Authorization"] = "Bearer \(self.accessToken)"

			
			center.observer = self
			return center
		}()
		
		/// A unique identifier of the account.
		public let identifier: String
		
		/// Returns true if the token is expired.
		public var isTokenExpired: Bool {
			if self.client.configuration.tokenNeverExpires {
				return false
			}
			return self.tokenExpirationDate.isPast
		}
		
		/// Refresh token.
		public var refreshToken: String?
		
		/// Expiration date of the token.
		public private(set) var tokenExpirationDate: Date
		
		public var dictionaryRepresentation: XUJSONDictionary {
			return [
				AccountKeys.identifierKey: self.identifier as AnyObject,
				AccountKeys.tokenExpirationDateKey: self.tokenExpirationDate as AnyObject
			]
		}
		
		public init(client: XUOAuth2Client, accessToken: String, refreshToken: String?, andExpirationDate expirationDate: Date) {
			self.client = client
			self.accessToken = accessToken
			self.identifier = UUID().uuidString
			self.refreshToken = refreshToken
			self.tokenExpirationDate = expirationDate

			self.save()
		}
		
		public init?(client: XUOAuth2Client, andDictionary dictionary: XUJSONDictionary) {
			guard
				let identifier = dictionary[AccountKeys.identifierKey] as? String,
				let expirationDate = dictionary[AccountKeys.tokenExpirationDateKey] as? Date
			else {
				return nil
			}
			
			let keychain = XUKeychainAccess.shared
			guard let accessToken = keychain.password(forUsername: identifier + "_access", inAccount: client.configuration.name) else {
				return nil
			}
			
			let refreshToken = keychain.password(forUsername: identifier + "_refresh", inAccount: client.configuration.name)
			if refreshToken == nil, !client.configuration.tokenNeverExpires {
				return nil
			}
			
			self.client = client
			
			self.identifier = identifier
			self.tokenExpirationDate = expirationDate
			
			self.accessToken = accessToken
			self.refreshToken = refreshToken
		}
		
		
		/// Renews authentication token and returns true if it was successful.
		/// The request for token renewal is synchronous.
		public func renewToken() -> Bool {
			guard let refreshToken = self.refreshToken else {
				if self.client.configuration.tokenNeverExpires {
					return true
				}
				
				fatalError("The client's configuration assumes token expiration, yet there is no refresh token available.")
			}
			
			XULog("Renewing token - expired \(XUTime.timeString(from: abs(Date.timeIntervalSinceReferenceDate - self.tokenExpirationDate.timeIntervalSinceReferenceDate))) ago.")
			
			let postDict: [String : String] = [
				"grant_type": "refresh_token",
				"refresh_token": refreshToken
			]
			
			var url = self.client.configuration.tokenEndpointURL
			if self.client.configuration.payloadFormat == .urlQuery {
				var query = url.queryDictionary
				query += postDict
				
				url = url.updatingQuery(to: query)
			}
			
			guard let obj = try? self.client.downloadCenter.downloadJSONDictionary(at: url, requestModifier: { request in
				request.setBasicAuthentication(user: self.client.configuration.clientID, password: self.client.configuration.secret)
				request.acceptType = .json
				
				switch self.client.configuration.payloadFormat {
				case .wwwForm:
					request.contentType = .wwwForm
					request.httpBody = postDict.urlQueryString.data(using: .utf8)
				case .json:
					request.contentType = .json
					request.setJSONBody(postDict)
				case .urlQuery:
					break // It's in the URL query.
				}

				request["Cookie"] = nil
				request.httpMethod = "POST"
				
				for (key, value) in self.client.configuration.additionalHTTPHeaders {
					request[key] = value
				}
			}) else {
				return false
			}
			
			guard let accessToken = obj["access_token"] as? String else {
				return false
			}
			
			if let refreshToken = obj["refresh_token"] as? String {
				self.refreshToken = refreshToken
			}
			
			let expiresInSeconds: TimeInterval = obj.double(forKey: "expires_in")
			self.accessToken = accessToken
			self.downloadCenter.automaticHeaderFieldValues["Authorization"] = "Bearer \(accessToken)"
			
			self.tokenExpirationDate = Date(timeIntervalSinceNow: expiresInSeconds)
			
			self.save()
			
			return true
		}
		
		/// Force-saves the token and refresh token. Currently a private method.
		private func save() {
			XUKeychainAccess.shared.save(password: self.accessToken, forUsername: self.identifier + "_access", inAccount: self.client.configuration.name)
			
			if let refreshToken = self.refreshToken {
				XUKeychainAccess.shared.save(password: refreshToken, forUsername: self.identifier + "_refresh", inAccount: self.client.configuration.name)
			}
			
			XUOAuth2Client.save()
		}
		
		
		public func downloadCenter(_ center: XUDownloadCenter, willDownloadContentFrom url: URL) {
			if self.isTokenExpired {
				_ = self.renewToken() // TODO: if we fail, notify the delegate
			}
			
		}
		
	}
	
	public enum AuthorizationResult {
		
		/// Authorized account.
		case authorized(Account)
		
		/// Authorization failed with error.
		case error(XUOAuth2ClientError)
		
	}
	
	private struct ClientKeys {
		static let accountsKey: String = "accounts"
		static let configurationKey: String = "configuration"
	}
	
	/// Returns a clint with `name`, if it is registered.
	public class func client(named name: String) -> XUOAuth2Client? {
		return self.registeredClients.first(where: { $0.configuration.name == name })
	}
	
	/// Reads clients from defaults. This is currently a private method, just 
	/// as save is.
	private class func readClientsFromDefaults() -> [XUOAuth2Client] {
		guard let dicts: [XUJSONDictionary] = XUPreferences.shared.oAuth2ClientDictionaries else {
			return []
		}
		
		return dicts.compactMap({ XUOAuth2Client(dictionary: $0) })
	}
	
	/// Registers a client with configuration. This causes the client to be 
	/// appended to XUOAuth2Client.registeredClients. If you no longer want to
	/// be registered, call unregister client.
	public class func registerClientWithConfiguration(_ configuration: XUOAuth2Configuration) -> XUOAuth2Client {
		if XUOAuth2Client.registeredClients.contains(where: { $0.configuration.name == configuration.name }) {
			XUFatalError("A client with the name \(configuration.name) is already registered. The configuration name must be unique amongst clients.")
		}
		
		let client = XUOAuth2Client(configuration: configuration)
		self.registeredClients.append(client)
		return client
	}
	
	/// All registered clients.
	public private(set) static var registeredClients: [XUOAuth2Client] = XUOAuth2Client.readClientsFromDefaults() {
		didSet {
			XUOAuth2Client.save()
		}
	}
	
	/// Saves the accounts to user defaults. Currently, it's a private method.
	private class func save() {
		XUPreferences.shared.oAuth2ClientDictionaries = self.registeredClients.map({ $0.dictionaryRepresentation })
	}
	
	/// Unregisters a client.
	public class func unregisterClient(_ client: XUOAuth2Client) {
		if let index = self.registeredClients.firstIndex(where: { $0 === client }) {
			self.registeredClients.remove(at: index)
			
			#if os(macOS)
				XUURLHandlingCenter.shared.remove(handler: client)
			#endif
		}
	}
	
	
	#if os(macOS)
		/// Only non-nil during authentication.
		private var _authorizationController: XUAuthorizationWebViewWindowController?
	#else
		private var _authorizationController: XUAuthorizationWebViewController?
	#endif
	
	/// Accounts of this client.
	public var accounts: [Account] = [] {
		didSet {
			XUOAuth2Client.save()
		}
	}
	
	/// Configuration this client was inited with.
	public let configuration: XUOAuth2Configuration
	
	/// Download center.
	private lazy var downloadCenter: XUDownloadCenter = XUDownloadCenter(identifier: "\(self.configuration.name) OAuth2 Client")
	
	
	/// Takes the code from redirection URL, requests authorization.
	private func _finishAuthorization(withCode code: String) {
		let postDict: [String : String] = [
			"clientID": self.configuration.clientID,
			"client_id": self.configuration.clientID,
			"client_secret": self.configuration.secret,
			"grant_type": "authorization_code",
			"code": code,
			"redirect_uri": self.configuration.redirectionURLString
		]
		
		var url = self.configuration.tokenEndpointURL
		if self.configuration.payloadFormat == .urlQuery {
			var query = url.queryDictionary
			query += postDict
			
			url = url.updatingQuery(to: query)
		}
		
		guard let obj = try? self.downloadCenter.downloadJSONDictionary(at: url, requestModifier: { request in
			request.setBasicAuthentication(user: self.configuration.clientID, password: self.configuration.secret)
			
			switch self.configuration.payloadFormat {
			case .wwwForm:
				request.contentType = .wwwForm
				request.httpBody = postDict.urlQueryString.data(using: .utf8)
			case .json:
				request.contentType = .json
				request.setJSONBody(postDict)
			case .urlQuery:
				break
			}
			
			request.acceptType = .json
			request.httpShouldHandleCookies = false
			request.cookies = nil
			request.httpMethod = "POST"
			
			for (key, value) in self.configuration.additionalHTTPHeaders {
				request[key] = value
			}
		}) else {
			DispatchQueue.onMain {
				self._authorizationController!.close(withResult: .error(.invalidAuthorizationResponse))
				self._authorizationController = nil
			}
			return
		}
		
		// Some responses include "Bearer" with capital "B".
		guard (obj["token_type"] as? String)?.lowercased() == "bearer" else {
			XULog("Token type is not bearer \(obj).")
			
			DispatchQueue.onMain {
				self._authorizationController!.close(withResult: .error(.invalidTokenType))
				self._authorizationController = nil
			}
			return
		}
		
		guard let accessToken = obj["access_token"] as? String else {
			XULog("No access token in \(obj).")
			
			DispatchQueue.onMain {
				self._authorizationController!.close(withResult: .error(.invalidAuthorizationResponse))
				self._authorizationController = nil
			}
			return
		}
		
		let refreshToken = obj["refresh_token"] as? String
		if !self.configuration.tokenNeverExpires, refreshToken == nil {
			XULog("No refresh token in \(obj).")
			
			DispatchQueue.onMain {
				self._authorizationController!.close(withResult: .error(.invalidAuthorizationResponse))
				self._authorizationController = nil
			}
			return
		}
		
		var expiresInSeconds: TimeInterval = obj.double(forKey: "expires_in")
		if self.configuration.tokenNeverExpires {
			expiresInSeconds = Date.distantFuture.timeIntervalSinceReferenceDate
		} else if expiresInSeconds == 0.0 {
			expiresInSeconds = XUTimeInterval.day * 14.0
		}
		
		DispatchQueue.onMain {
			let account = Account(client: self, accessToken: accessToken, refreshToken: refreshToken, andExpirationDate: Date(timeIntervalSinceNow: expiresInSeconds))
			self.accounts.append(account)
			
			self._authorizationController!.close(withResult: .authorized(account))
			self._authorizationController = nil
		}
	}
	
	public var dictionaryRepresentation: XUJSONDictionary {
		return [
			ClientKeys.accountsKey: self.accounts.map({ $0.dictionaryRepresentation }),
			ClientKeys.configurationKey: self.configuration.dictionaryRepresentation
		]
	}
	
	/// On iOS, call this method from your app delegate's application(_:openURL:...).
	/// On OS X, refrain from calling this method directly, XUOAuth2Client handles
	/// this automatically for you via XUURLHandlingCenter.
	public func handleRedirectURL(_ url: URL) {
		XUAssert(_authorizationController != nil, "Handling an authorization call while no controller is being displayed!")
		
		guard let query = url.query else {
			_authorizationController!.close(withResult: .error(.invalidRedirectionURL))
			_authorizationController = nil
			return
		}
		
		guard let code = query.urlQueryDictionary["code"] else {
			_authorizationController!.close(withResult: .error(.invalidRedirectionURL))
			_authorizationController = nil
			return
		}
		
		DispatchQueue.global(qos: .default).async {
			self._finishAuthorization(withCode: code)
		}
	}
	
	/// Private initializer.
	private init(configuration: XUOAuth2Configuration) {
		self.configuration = configuration
	}

	private convenience init?(dictionary: XUJSONDictionary) {
		guard
			let configurationDict = dictionary[ClientKeys.configurationKey] as? XUJSONDictionary,
			let accountDicts = dictionary[ClientKeys.accountsKey] as? [XUJSONDictionary]
		else {
			return nil
		}
		
		guard let configuration = XUOAuth2Configuration(dictionary: configurationDict) else {
			return nil
		}
		
		self.init(configuration: configuration)
		
		self.accounts += accountDicts.compactMap({ Account(client: self, andDictionary: $0) })
	}
	
	#if os(macOS)
		public func startAccountAuthorization(withCompletionHandler completionHandler: ((AuthorizationResult) -> Void)?) {
			XUURLHandlingCenter.shared.add(handler: self, forURLScheme: configuration.redirectionScheme)
			
			_authorizationController = XUAuthorizationWebViewWindowController(url: self.configuration.authorizationURL)
			_authorizationController!.runModal(withCompletionHandler: { result in
				XUURLHandlingCenter.shared.remove(handler: self, forURLScheme: self.configuration.redirectionScheme)
				completionHandler?(result)
				
				XUOAuth2Client.save()
			})
		}
	#else
		public func startAccountAuthorization(fromController controller: UIViewController, withCompletionHandler completionHandler: ((AuthorizationResult) -> Void)?) {
			_authorizationController = XUAuthorizationWebViewController(url: self.configuration.authorizationURL)
			_authorizationController!.present(fromController: controller, withCompletionHandler: {
				completionHandler?($0)
				
				XUOAuth2Client.save()
			})
		}
	#endif
}

#if os(macOS)
extension XUOAuth2Client: XUURLHandler {
	
	public func handlerShouldProcessURL(_ URL: URL) {
		self.handleRedirectURL(URL)
	}
	
}
#endif
