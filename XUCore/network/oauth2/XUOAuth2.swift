//
//  XUOAuth2.swift
//  XUCore
//
//  Created by Charlie Monroe on 6/21/16.
//  Copyright © 2016 Charlie Monroe Software. All rights reserved.
//

import Foundation

public final class XUOAuth2Configuration {
	
	private struct ConfigurationKeys {
		static let authorizationBaseURLStringKey = "authorizationBaseURLString"
		static let clientIDKey = "clientID"
		static let nameKey = "name"
		static let redirectionSchemeKey = "redirectionScheme"
		static let secretKey = "secret"
		static let tokenEndpointURLStringKey = "tokenEndpointURLString"
	}
	
	
	/// URL used for authorization. This must be the base URL with no query.
	/// Passing a URL that includes a GET query in the URL will trigger an 
	/// assertion failure in the initializer.
	public let authorizationBaseURL: NSURL
	
	/// Authorization URL put together from authorizationBaseURL, redirectionScheme,
	/// and clientID.
	public var authorizationURL: NSURL {
		let queryDict: [String : String] = [
			"client_id": self.clientID,
			"response_type": "code",
			"redirect_uri": self.redirectionURLString
		]
		
		return NSURL(string: self.authorizationBaseURL.absoluteString + "?" + queryDict.URLQueryString)!
	}
	
	/// ID of the client.
	public let clientID: String
	
	/// Name of the client. Used for saving the accounts, etc. It should be unique
	/// as initing two clients with the same name will cause fatalError.
	public let name: String
	
	/// URL scheme that the app must be capable of opening. This is used for
	/// redirection within the WebView displayed.
	public let redirectionScheme: String
	
	/// The redirection URL passed to the OAuth2 authority.
	public var redirectionURLString: String {
		return "\(self.redirectionScheme)://approve"
	}
	
	/// Client secret.
	public let secret: String
	
	/// URL for token.
	public let tokenEndpointURL: NSURL
	
	
	public var dictionaryRepresentation: [String : String] {
		return [
			ConfigurationKeys.authorizationBaseURLStringKey: self.authorizationBaseURL.absoluteString,
			ConfigurationKeys.clientIDKey: self.clientID,
			ConfigurationKeys.nameKey: self.name,
			ConfigurationKeys.redirectionSchemeKey: self.redirectionScheme,
			ConfigurationKeys.secretKey: self.secret,
			ConfigurationKeys.tokenEndpointURLStringKey: self.tokenEndpointURL.absoluteString
		]
	}
	
	/// Designated initializer.
	public init(authorizationBaseURL: NSURL, clientID: String, name: String, redirectionScheme: String, secret: String, tokenEndpointURL: NSURL) {
		assert(authorizationBaseURL.query == nil, "authorizationBaseURL with query is not supported.")
		
		self.authorizationBaseURL = authorizationBaseURL
		self.clientID = clientID
		self.name = name
		self.redirectionScheme = redirectionScheme
		self.secret = secret
		self.tokenEndpointURL = tokenEndpointURL
	}
	
	public convenience init?(dictionary dict: [String : String]) {
		guard let
			authorizationBaseURLString = dict[ConfigurationKeys.authorizationBaseURLStringKey],
			clientID = dict[ConfigurationKeys.clientIDKey],
			name = dict[ConfigurationKeys.nameKey],
			redirectionScheme = dict[ConfigurationKeys.redirectionSchemeKey],
			secret = dict[ConfigurationKeys.secretKey],
			tokenEndpointURLString = dict[ConfigurationKeys.tokenEndpointURLStringKey] else {
			return nil
		}
		
		guard let authorizationBaseURL = NSURL(string: authorizationBaseURLString), tokenEndpointURL = NSURL(string: tokenEndpointURLString) else {
			return nil
		}
		
		self.init(authorizationBaseURL: authorizationBaseURL, clientID: clientID, name: name, redirectionScheme: redirectionScheme, secret: secret, tokenEndpointURL: tokenEndpointURL)
	}
	
}

public let XUOAuth2ClientErrorDomain = "XUOAuth2ClientErrorDomain"

public enum XUOAuth2ClientError: Int {
	
	/// This error happens when the user grants authorization to the app in the
	/// window, the app receives a redirection with a valid code, but then, loading
	/// the authorization response fails, or the response contains no access token.
	case InvalidAuthorizationResponse
	
	/// The redirection URL is invalid. This is usually because it's missing the
	/// code in the query part of the URL.
	case InvalidRedirectionURL
	
	/// This error happens when the user grants authorization to the app in the
	/// window, the app receives a redirection with a valid code, loads the 
	/// authorization response, but it specifies a different type of the token
	/// other than "bearer".
	case InvalidTokenType
	
	/// User when the user deliberately closes the authorization window before 
	/// it's done with the authorization.
	case UserCancelled
	
	/// Converts self into NSError.
	public var error: NSError {
		let errorString: String
		
		switch self {
		case .InvalidTokenType:
			errorString = XULocalizedString("Server responded with unknown token type.")
		case .InvalidAuthorizationResponse:
			errorString = XULocalizedString("Server provided invalid authorization response.")
		case .InvalidRedirectionURL:
			errorString = XULocalizedString("Server has redirected with invalid URL.")
		case .UserCancelled:
			errorString = XULocalizedString("User has cancelled the authorization.")
		}
		
		return NSError(domain: XUOAuth2ClientErrorDomain, code: self.rawValue, userInfo: [
			NSLocalizedFailureReasonErrorKey: errorString
		])
	}
	
}


private let XUOAuth2AccountsKey = "XUOAuth2Accounts"

public final class XUOAuth2Client {
	
	/// A particular account.
	public final class Account: XUDownloadCenterOwner {
		
		private struct AccountKeys {
			static let identifierKey: String = "identifier"
			static let tokenExpirationDateKey: String = "tokenExpirationDate"
		}
		
		
		/// Authentication token.
		public private(set) var accessToken: String {
			didSet {
				XUOAuth2Client.save()
			}
		}
		
		/// Client this account belongs to.
		public private(set) weak var client: XUOAuth2Client!
		
		/// Download center for this particular account. The account automatically
		/// sets the authorization token and automatically renews the token when
		/// you use this download center.
		public lazy var downloadCenter: XUDownloadCenter = XUDownloadCenter(owner: self)
		
		/// A unique identifier of the account.
		public let identifier: String
		
		/// Returns true if the token is expired.
		public var isTokenExpired: Bool {
			return self.tokenExpirationDate.isPast
		}
		
		/// Refresh token.
		public let refreshToken: String
		
		/// Expiration date of the token.
		public private(set) var tokenExpirationDate: NSDate
		
		
		public var dictionaryRepresentation: XUJSONDictionary {
			return [
				AccountKeys.identifierKey: self.identifier,
				AccountKeys.tokenExpirationDateKey: self.tokenExpirationDate
			]
		}
		
		public func downloadCenter(downloadCenter: XUDownloadCenter, didEncounterError error: XUDownloadCenterError) {
			/// No-op
		}
		
		public init(client: XUOAuth2Client, accessToken: String, refreshToken: String, andExpirationDate expirationDate: NSDate) {
			self.client = client
			self.accessToken = accessToken
			self.identifier = String.UUIDString
			self.refreshToken = refreshToken
			self.tokenExpirationDate = expirationDate
			
			XUKeychainAccess.sharedAccess.savePassword(self.accessToken, forUsername: self.identifier + "_access", inAccount: self.client.configuration.name)
			XUKeychainAccess.sharedAccess.savePassword(self.accessToken, forUsername: self.identifier + "_refresh", inAccount: self.client.configuration.name)
		}
		
		public init?(client: XUOAuth2Client, andDictionary dictionary: XUJSONDictionary) {
			guard let
				identifier = dictionary[AccountKeys.identifierKey] as? String,
				expirationDate = dictionary[AccountKeys.tokenExpirationDateKey] as? NSDate else {
				return nil
			}
			
			let keychain = XUKeychainAccess.sharedAccess
			guard let
				accessToken = keychain.passwordForUsername(identifier + "_access", inAccount: client.configuration.name),
				refreshToken = keychain.passwordForUsername(identifier + "_refresh", inAccount: client.configuration.name) else {
				return nil
			}
			
			self.client = client
			
			self.identifier = identifier
			self.tokenExpirationDate = expirationDate
			
			self.accessToken = accessToken
			self.refreshToken = refreshToken
		}
		
		public var name: String {
			return "OAuth2 - \(self.identifier) - \(self.client.configuration.name)"
		}
		
		/// Renews authentication token and returns true if it was successful.
		/// The request for token renewal is synchronous.
		public func renewToken() -> Bool {
			let postDict: [String : String] = [
				"grant_type": "refresh_token",
				"refresh_token": self.refreshToken
			]
			
			guard let obj = self.client.downloadCenter.downloadJSONDictionaryAtURL(self.client.configuration.tokenEndpointURL, withModifier: { (request) in
				request.acceptType = XUMutableURLRequestJSONHeaderFieldValue
				request.addWWWFormContentToHeader()
				request["Cookie"] = nil
				request.HTTPMethod = "POST"
				request.HTTPBody = postDict.URLQueryString.dataUsingEncoding(NSUTF8StringEncoding)
			}) else {
				return false
			}
			
			guard let accessToken = obj["access_token"] as? String else {
				return false
			}
			
			let expiresInSeconds: NSTimeInterval = obj.doubleForKey("expires_in")
			self.accessToken = accessToken
			self.tokenExpirationDate = NSDate(timeIntervalSinceNow: expiresInSeconds)
			return false // TODO
		}
		
		public func setupURLRequest(request: NSMutableURLRequest, forDownloadingPageAtURL pageURL: NSURL) {
			if self.isTokenExpired {
				self.renewToken() // TODO: if we fail, notify the delegate
			}
			
			request["Authorization"] = "Bearer \(self.accessToken)"
		}
		
	}
	
	public enum AuthorizationResult {
		
		/// Authorized account.
		case Authorized(Account)
		
		/// Authorization failed with error.
		case Error(XUOAuth2ClientError)
		
	}
	
	private struct ClientKeys {
		static let accountsKey: String = "accounts"
		static let configurationKey: String = "configuration"
	}
	
	/// Returns a clint with `name`, if it is registered.
	public class func client(named name: String) -> XUOAuth2Client? {
		return self.registeredClients.find({ $0.configuration.name == name })
	}
	
	/// Reads clients from defaults. This is currently a private method, just 
	/// as save is.
	private class func readClientsFromDefaults() -> [XUOAuth2Client] {
		guard let dicts: [XUJSONDictionary] = XUPreferencesObjectForKey(XUOAuth2AccountsKey) else {
			return []
		}
		
		return dicts.flatMap({ XUOAuth2Client(dictionary: $0) })
	}
	
	/// Registers a client with configuration. This causes the client to be 
	/// appended to XUOAuth2Client.registeredClients. If you no longer want to
	/// be registered, call unregister client.
	public class func registerClientWithConfiguration(configuration: XUOAuth2Configuration) -> XUOAuth2Client {
		if XUOAuth2Client.registeredClients.contains({ $0.configuration.name == configuration.name }) {
			fatalError("A client with the name \(configuration.name) is already registered. The configuration name must be unique amongst clients.")
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
		XUPreferencesSetObjectForKey(self.registeredClients.map({ $0.dictionaryRepresentation }), key: XUOAuth2AccountsKey)
	}
	
	/// Unregisters a client.
	public class func unregisterClient(client: XUOAuth2Client) {
		if let index = self.registeredClients.indexOf({ $0 === client }) {
			self.registeredClients.removeAtIndex(index)
			
			#if os(OSX)
				XUURLHandlingCenter.defaultCenter.removeHandler(client)
			#endif
		}
	}
	
	
	#if os(OSX)
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
	private lazy var downloadCenter: XUDownloadCenter = XUDownloadCenter(owner: self)
	
	
	/// Takes the code from redirection URL, requests authorization.
	private func _finishAuthorization(withCode code: String) {
		let postDict: [String : String] = [
			"clientID": self.configuration.clientID,
			"client_secret": self.configuration.secret,
			"grant_type": "authorization_code",
			"code": code,
			"redirect_uri": self.configuration.redirectionURLString
		]
		
		guard let obj = self.downloadCenter.downloadJSONDictionaryAtURL(self.configuration.tokenEndpointURL, withModifier: { (request) in
			request.setUsername(self.configuration.clientID, andPassword: self.configuration.secret)
			request.acceptType = XUMutableURLRequestJSONHeaderFieldValue
			request.addWWWFormContentToHeader()
			request["Cookie"] = nil
			request.HTTPMethod = "POST"
			request.HTTPBody = postDict.URLQueryString.dataUsingEncoding(NSUTF8StringEncoding)
		}) else {
			XU_PERFORM_BLOCK_ON_MAIN_THREAD {
				self._authorizationController!.close(withResult: .Error(.InvalidAuthorizationResponse))
				self._authorizationController = nil
			}
			return
		}
		
		guard obj["token_type"] as? String == "bearer" else {
			XULog("Token type is not bearer \(obj).")
			
			XU_PERFORM_BLOCK_ON_MAIN_THREAD {
				self._authorizationController!.close(withResult: .Error(.InvalidTokenType))
				self._authorizationController = nil
			}
			return
		}
		
		guard let accessToken = obj["access_token"] as? String, refreshToken = obj["refresh_token"] as? String else {
			XULog("No access token or refresh token in \(obj).")
			
			XU_PERFORM_BLOCK_ON_MAIN_THREAD {
				self._authorizationController!.close(withResult: .Error(.InvalidAuthorizationResponse))
				self._authorizationController = nil
			}
			return
		}
		
		var expiresInSeconds: NSTimeInterval = obj.doubleForKey("expires_in")
		if expiresInSeconds == 0.0 {
			expiresInSeconds = XUTimeInterval.day
		}
		
		XU_PERFORM_BLOCK_ON_MAIN_THREAD {
			let account = Account(client: self, accessToken: accessToken, refreshToken: refreshToken, andExpirationDate: NSDate(timeIntervalSinceNow: expiresInSeconds))
			self.accounts.append(account)
			
			self._authorizationController!.close(withResult: .Authorized(account))
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
	public func handleRedirectURL(URL: NSURL) {
		assert(_authorizationController != nil, "Handling an authorization call while no controller is being displayed!")
		
		guard let query = URL.query else {
			_authorizationController!.close(withResult: .Error(.InvalidRedirectionURL))
			_authorizationController = nil
			return
		}
		
		guard let code = query.URLQueryDictionary["code"] else {
			_authorizationController!.close(withResult: .Error(.InvalidRedirectionURL))
			_authorizationController = nil
			return
		}
		
		XU_PERFORM_BLOCK_ASYNC {
			self._finishAuthorization(withCode: code)
		}
	}
	
	/// Private initializer.
	private init(configuration: XUOAuth2Configuration) {
		self.configuration = configuration
		
		#if os(OSX)
			XUURLHandlingCenter.defaultCenter.addHandler(self, forURLScheme: configuration.redirectionScheme)
		#endif
	}

	private convenience init?(dictionary: XUJSONDictionary) {
		guard let
			configurationDict = dictionary[ClientKeys.configurationKey] as? [String : String],
			accountDicts = dictionary[ClientKeys.accountsKey] as? [XUJSONDictionary] else {
			return nil
		}
		
		guard let configuration = XUOAuth2Configuration(dictionary: configurationDict) else {
			return nil
		}
		
		self.init(configuration: configuration)
		
		self.accounts += accountDicts.flatMap({ Account(client: self, andDictionary: $0) })
	}
	
	#if os(OSX)
		public func startAccountAuthorization(withCompletionHandler completionHandler: ((AuthorizationResult) -> Void)?) {
			_authorizationController = XUAuthorizationWebViewWindowController(URL: self.configuration.authorizationURL)
			_authorizationController!.runModal(withCompletionHandler: completionHandler)
		}
	#else
		public func startAccountAuthorization(fromController controller: UIViewController, withCompletionHandler completionHandler: ((AuthorizationResult) -> Void)?) {
			_authorizationController = XUAuthorizationWebViewController(URL: self.configuration.authorizationURL)
			_authorizationController!.present(fromController: controller, withCompletionHandler: completionHandler)
		}
	#endif
	
}

extension XUOAuth2Client: XUDownloadCenterOwner {
	
	public var name: String {
		return "\(self.configuration.name) OAuth2 Client"
	}
	
	public func downloadCenter(downloadCenter: XUDownloadCenter, didEncounterError error: XUDownloadCenterError) {
		///
	}
	
}

#if os(OSX)
	extension XUOAuth2Client: XUURLHandler {
		
		@objc public func handlerShouldProcessURL(URL: NSURL) {
			self.handleRedirectURL(URL)
		}

	}
#endif

