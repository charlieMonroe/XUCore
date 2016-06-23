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
		static let authorizationURLStringKey = "authorizationURLString"
		static let clientIDKey = "clientID"
		static let nameKey = "name"
		static let redirectionSchemeKey = "redirectionScheme"
		static let secretKey = "secret"
		static let tokenURLStringKey = "tokenURLString"
	}
	
	
	/// URL used for authorization.
	public let authorizationURL: NSURL
	
	/// ID of the client.
	public let clientID: String
	
	/// Name of the client. Used for saving the token, etc.
	public let name: String
	
	/// URL scheme that the app must be capable of opening. This is used for
	/// redirection within the WebView displayed.
	public let redirectionScheme: String
	
	/// Client secret.
	public let secret: String
	
	/// URL for token.
	public let tokenURL: NSURL
	
	
	public var dictionaryRepresentation: [String : String] {
		return [
			ConfigurationKeys.authorizationURLStringKey: self.authorizationURL.absoluteString,
			ConfigurationKeys.clientIDKey: self.clientID,
			ConfigurationKeys.nameKey: self.name,
			ConfigurationKeys.redirectionSchemeKey: self.redirectionScheme,
			ConfigurationKeys.secretKey: self.secret,
			ConfigurationKeys.tokenURLStringKey: self.tokenURL.absoluteString
		]
	}
	
	/// Designated initializer.
	public init(authorizationURL: NSURL, clientID: String, name: String, redirectionScheme: String, secret: String, tokenURL: NSURL) {
		self.authorizationURL = authorizationURL
		self.clientID = clientID
		self.name = name
		self.redirectionScheme = redirectionScheme
		self.secret = secret
		self.tokenURL = tokenURL
	}
	
	public convenience init?(dictionary dict: [String : String]) {
		guard let
			authorizationURLString = dict[ConfigurationKeys.authorizationURLStringKey],
			clientID = dict[ConfigurationKeys.clientIDKey],
			name = dict[ConfigurationKeys.nameKey],
			redirectionScheme = dict[ConfigurationKeys.redirectionSchemeKey],
			secret = dict[ConfigurationKeys.secretKey],
			tokenURLString = dict[ConfigurationKeys.tokenURLStringKey] else {
			return nil
		}
		
		guard let authorizationURL = NSURL(string: authorizationURLString), tokenURL = NSURL(string: tokenURLString) else {
			return nil
		}
		
		self.init(authorizationURL: authorizationURL, clientID: clientID, name: name, redirectionScheme: redirectionScheme, secret: secret, tokenURL: tokenURL)
	}
	
}

public final class XUOAuth2Client: XUURLHandler {
	
	/// A particular account.
	public final class Account: XUDownloadCenterOwner {
		
		/// A link to the account's parent clinet.
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
		
		/// Authentication token.
		public var token: String
		
		/// Expiration date of the token.
		public var tokenExpirationDate: NSDate
		
		public func downloadCenter(downloadCenter: XUDownloadCenter, didEncounterError error: XUDownloadCenterError) {
			/// No-op
		}
		
		public init(client: XUOAuth2Client, token: String, expirationDate: NSDate) {
			self.client = client
			self.token = token
			self.tokenExpirationDate = expirationDate
			self.identifier = String.UUIDString
		}
		
		public var name: String {
			return "OAuth2 - \(self.identifier) - \(self.client.configuration.name)"
		}
		
		/// Renews authentication token and returns true if it was successful.
		/// The request for token renewal is synchronous.
		public func renewToken() -> Bool {
			return false // TODO
		}
		
		public func setupURLRequest(request: NSMutableURLRequest, forDownloadingPageAtURL pageURL: NSURL) {
			if self.isTokenExpired {
				self.renewToken() // TODO: if we fail, notify the delegate
			}
			
			// TODO: sign request
		}
		
	}
	
	
	/// Registers a client with configuration. This causes the client to be 
	/// appended to XUOAuth2Client.registeredClients. If you no longer want to
	/// be registered, call unregister client.
	public class func registerClientWithConfiguration(configuration: XUOAuth2Configuration) -> XUOAuth2Client {
		let client = XUOAuth2Client(configuration: configuration)
		self.registeredClients.append(client)
		return client
	}
	
	/// All registered clients.
	public private(set) static var registeredClients: [XUOAuth2Client] = []
	
	/// Unregisters a client.
	public class func unregisterClient(client: XUOAuth2Client) {
		if let index = self.registeredClients.indexOf({ $0 === client }) {
			self.registeredClients.removeAtIndex(index)
			
			XUURLHandlingCenter.defaultCenter.removeHandler(client)
		}
	}
	
	
	/// Accounts of this client.
	public var accounts: [Account] = []
	
	/// Configuration this client was inited with.
	public let configuration: XUOAuth2Configuration
	
	@objc public func handlerShouldProcessURL(URL: NSURL) {
		/// TODO - read the token and create an account.
	}
	
	/// Private initializer.
	private init(configuration: XUOAuth2Configuration) {
		self.configuration = configuration
		
		XUURLHandlingCenter.defaultCenter.addHandler(self, forURLScheme: configuration.redirectionScheme)
	}
	
}

