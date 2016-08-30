//
//  XUKeychainAccess_iOS.swift
//  XUCore
//
//  Created by Charlie Monroe on 6/24/16.
//  Copyright © 2016 Charlie Monroe Software. All rights reserved.
//

import Foundation

public class XUKeychainAccess {
	
	public static let sharedAccess: XUKeychainAccess = XUKeychainAccess()
	
	private func _dictionaryForUsername(username: String, inAccount account: String, accessGroup: String?) -> [String : AnyObject]? {
		var genericPasswordQuery: [String : AnyObject] = [:]
		genericPasswordQuery[kSecClass as String] = kSecClassGenericPassword
		genericPasswordQuery[kSecAttrAccount as String] = "\(account): \(username)"
		
		if let accessGroup = accessGroup {
			#if (arch(i386) || arch(x86_64)) && os(iOS)
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
		if SecItemCopyMatching(genericPasswordQuery, &genericResult) != noErr {
			return nil
		}
		
		guard let currentDictionary = genericResult as? [String : AnyObject] else {
			XULog("Result returned for user \(username) in account \(account) is not a dictionary: \(genericResult.descriptionWithDefaultValue()).")
			return nil
		}

		return currentDictionary
	}
	
	
	/// Fetches a password for username in account from Keychain.
	public func passwordForUsername(username: String, inAccount account: String, accessGroup: String? = nil) -> String? {
		guard let currentDictionary = self._dictionaryForUsername(username, inAccount: account, accessGroup: accessGroup) else {
			XULog("Failed to fetch password for \(username) in \(account).")
			return nil
		}
		
		let returnDictionary = currentDictionary + [
			(kSecReturnData as String): kCFBooleanTrue,
			(kSecClass as String): kSecClassGenericPassword
		]
		
		var genericPasswordData: AnyObject?
		guard SecItemCopyMatching(returnDictionary, &genericPasswordData) == noErr else {
			XULog("Failed to copy password data for user \(username) in account \(account).")
			return nil
		}
		
		guard let data = genericPasswordData as? NSData, password = String(data: data) else {
			XULog("Failed to create password from password data \(genericPasswordData.descriptionWithDefaultValue())")
			return nil
		}
		
		return password
	}
	
	/// Saves password for username in account to Keychain. Returns true if the
	/// operation was successful, false otherwise.
	public func savePassword(password: String, forUsername username: String, inAccount account: String, accessGroup: String? = nil) -> Bool {
		var dict: [String : AnyObject]
		let isNew: Bool
		if let currentDictionary = self._dictionaryForUsername(username, inAccount: account, accessGroup: accessGroup) {
			dict = currentDictionary
			isNew = false
		} else {
			dict = [:]

			if let accessGroup = accessGroup {
				#if (arch(i386) || arch(x86_64)) && os(iOS)
				#else
					dict[kSecAttrAccessGroup as String] = accessGroup
				#endif
			}
			
			dict[kSecClass as String] = kSecClassGenericPassword
			dict[kSecAttrAccount as String] = "\(account): \(username)"
			isNew = true
		}
		
		dict[kSecValueData as String] = password.dataUsingEncoding(NSUTF8StringEncoding)

		if isNew {
			return SecItemAdd(dict, nil) == noErr
		} else {
			var updateItem = dict
			updateItem[kSecClass as String] = kSecClassGenericPassword
			
			dict[kSecClass as String] = nil
			dict[kSecAttrAccessGroup as String] = nil
			
			return SecItemUpdate(updateItem, dict) == noErr
		}
	}
	
	private init() {
	
	}
	
}
