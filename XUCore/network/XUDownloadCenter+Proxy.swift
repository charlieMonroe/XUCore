//
//  XUDownloadCenter+Proxy.swift
//  XUCore
//
//  Created by Charlie Monroe on 3/21/18.
//  Copyright © 2018 Charlie Monroe Software. All rights reserved.
//

import Foundation

public extension XUDownloadCenter {

	/// Configuration of the proxy.
	struct ProxyConfiguration {
		
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
			
			#if os(macOS)
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
				guard
					let address = dictionary[DictionaryKeys.Address] as? String,
					let port = dictionary[DictionaryKeys.Port] as? Int
				else {
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
			guard
				let hostDict = dictionary[DictionaryKeys.Host] as? XUJSONDictionary,
				let host = Host(dictionary: hostDict),
				let proxyTypeValue = dictionary[DictionaryKeys.ProxyType] as? Int,
				let proxyType = ProxyType(rawValue: proxyTypeValue)
			else {
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
			#if os(macOS)
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
	
}
