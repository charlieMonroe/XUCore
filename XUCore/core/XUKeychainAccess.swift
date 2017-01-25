//
//  XUKeychainAccess.swift
//  XUCore
//
//  Created by Charlie Monroe on 1/27/16.
//  Copyright © 2016 Charlie Monroe Software. All rights reserved.
//

import Foundation
import Security

public struct XUKeychainAccess {
	
	public static let sharedAccess: XUKeychainAccess = XUKeychainAccess()
	
	
	/// Fetches a password for username in account from Keychain.
	public func password(forUsername username: String, inAccount account: String) -> String? {
		if username.isEmpty {
			return nil
		}
		
		var passLen: UInt32 = 0
		var passBytes: UnsafeMutableRawPointer? = nil
		var item: SecKeychainItem? = nil
		
		let result = SecKeychainFindGenericPassword(nil,
			UInt32(strlen(account)), account,
			UInt32(strlen(username)), username,
			&passLen, &passBytes,
			&item
		)
		
		if noErr != result {
			return nil
		}
		
		defer {
			// release buffer allocated by SecKeychainFindGenericPassword
			SecKeychainItemFreeContent(nil, passBytes)
		}
		
		if passLen > 0 {
			let str = NSString(bytes: passBytes!, length: Int(passLen), encoding: NSString.defaultCStringEncoding)
			return str as String?
		} else {
			return "" // if we have noErr but also no length, password is empty
		}
	}
	
	/// Saves password for username in account to Keychain. Returns true if the
	/// operation was successful, false otherwise.
	@discardableResult
	public func save(password: String, forUsername username: String, inAccount account: String) -> Bool {
		if username.isEmpty {
			return false
		}
		
		let status = SecKeychainAddGenericPassword(nil,
			UInt32(strlen(account)), account,
			UInt32(strlen(username)), username,
			UInt32(strlen(password)), password,
			nil
		)
		
		if status == noErr {
			return true // It's all fine
		}
		
		if status != errSecDuplicateItem {
			// Some other error.
			XULog("Failed to save keychain item for \(username) in \(account): \(status)")
			return false
		}
		
		var passLen: UInt32 = 0
		var passBytes: UnsafeMutableRawPointer? = nil
		var item: SecKeychainItem? = nil

		let result = SecKeychainFindGenericPassword(nil,
			UInt32(strlen(account)), account,
			UInt32(strlen(username)), username,
			&passLen, &passBytes,
			&item
		)
		
		if noErr != result {
			// Some other error.
			XULog("Fatal error: Keychain reported this item as duplicate, while not being able to find it.")
			XULog("Failed to save keychain item for \(username) in \(account): \(result)")
			return false
		}
		
		SecKeychainItemFreeContent(nil, passBytes)
		let savedPassword = NSString(bytes: passBytes!, length: Int(passLen), encoding: NSString.defaultCStringEncoding) as String?
		if savedPassword == password {
			return true // It's the same password, ignore
		}
		
		let modificationResult = SecKeychainItemModifyContent(item!, nil, UInt32(strlen(password)), password)
		if modificationResult == noErr {
			return true
		}
		
		XULog("Failed to update keychain item for \(username) in \(account): \(modificationResult)")
		return false
	}
	
	
	private init() {}
	
}
