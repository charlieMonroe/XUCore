//
//  XUKeychainAccess_iOS.swift
//  XUCore
//
//  Created by Charlie Monroe on 6/24/16.
//  Copyright © 2016 Charlie Monroe Software. All rights reserved.
//

import Foundation

public struct XUKeychainAccess {
	
	public static let shared: XUKeychainAccess = XUKeychainAccess()
	
	private func _dictionaryForUsername(username: String, inAccount account: String, accessGroup: String?) -> [String : Any]? {
		var genericPasswordQuery: [String : Any] = [:]
		genericPasswordQuery[kSecClass as String] = kSecClassGenericPassword
		genericPasswordQuery[kSecAttrAccount as String] = "\(account): \(username)" as AnyObject?
		
		if let accessGroup = accessGroup {
			#if targetEnvironment(simulator)
				// Ignore the access group if running on the iPhone simulator.
				//
				// Apps that are built for the simulator aren't signed, so there's no keychain access group
				// for the simulator to check. This means that all apps can see all keychain items when run
				// on the simulator.
				//
				// If a SecItem contains an access group attribute, SecItemAdd and SecItemUpdate on the
				// simulator will return -25243 (errSecNoAccessForItem).
			#else
				genericPasswordQuery[kSecAttrAccessGroup as String] = accessGroup
			#endif
		}
		
		// Use the proper search constants, return only the attributes of the first match.
		genericPasswordQuery[kSecMatchLimit as String] = kSecMatchLimitOne
		genericPasswordQuery[kSecReturnAttributes as String] = kCFBooleanTrue
		
		var genericResult: AnyObject? = nil
		if SecItemCopyMatching(genericPasswordQuery as CFDictionary, &genericResult) != noErr {
			return nil
		}
		
		guard let currentDictionary = genericResult as? [String : Any] else {
			XULog("Result returned for user \(username) in account \(account) is not a dictionary: \(genericResult.descriptionWithDefaultValue()).")
			return nil
		}

		return currentDictionary
	}
	
	
	/// Fetches a password for username in account from Keychain.
	public func password(forUsername username: String, inAccount account: String, accessGroup: String? = nil) -> String? {
		guard let currentDictionary = self._dictionaryForUsername(username: username, inAccount: account, accessGroup: accessGroup) else {
			XULog("Failed to fetch password for \(username) in \(account).")
			return nil
		}
		
		let returnDictionary = currentDictionary + [
			(kSecReturnData as String): kCFBooleanTrue!,
			(kSecClass as String): kSecClassGenericPassword
		]
		
		var genericPasswordData: AnyObject?
		guard SecItemCopyMatching(returnDictionary as CFDictionary, &genericPasswordData) == noErr else {
			XULog("Failed to copy password data for user \(username) in account \(account).")
			return nil
		}
		
		guard let data = genericPasswordData as? Data, let password = String(data: data) else {
			XULog("Failed to create password from password data \(genericPasswordData.descriptionWithDefaultValue())")
			return nil
		}
		
		return password
	}
	
	/// Saves password for username in account to Keychain. Returns true if the
	/// operation was successful, false otherwise.
	@discardableResult
	public func save(password: String, forUsername username: String, inAccount account: String, accessGroup: String? = nil) -> Bool {
		var dict: [String : Any]
		let isNew: Bool
		if let currentDictionary = self._dictionaryForUsername(username: username, inAccount: account, accessGroup: accessGroup) {
			dict = currentDictionary
			isNew = false
		} else {
			dict = [:]

			if let accessGroup = accessGroup {
				#if targetEnvironment(simulator)
				#else
					dict[kSecAttrAccessGroup as String] = accessGroup
				#endif
			}
			
			dict[kSecClass as String] = kSecClassGenericPassword
			dict[kSecAttrAccount as String] = "\(account): \(username)"
			isNew = true
		}
		
		dict[kSecValueData as String] = password.data(using: .utf8)

		if isNew {
			return SecItemAdd(dict as CFDictionary, nil) == noErr
		} else {
			var updateItem = dict
			updateItem[kSecClass as String] = kSecClassGenericPassword
			
			dict[kSecClass as String] = nil
			dict[kSecAttrAccessGroup as String] = nil
			
			return SecItemUpdate(updateItem as CFDictionary, dict as CFDictionary) == noErr
		}
	}
	
	private init() {}
	
}
