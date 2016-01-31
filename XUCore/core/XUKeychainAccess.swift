//
//  XUKeychainAccess.swift
//  XUCore
//
//  Created by Charlie Monroe on 1/27/16.
//  Copyright © 2016 Charlie Monroe Software. All rights reserved.
//

import Cocoa

public class XUKeychainAccess: NSObject {
	
	public static let sharedAccess: XUKeychainAccess = XUKeychainAccess()
	
	/// Fetches a password for username in account from Keychain.
	public func passwordForUsername(username: String, inAccount account: String) -> String? {
		let utf8account = (account as NSString).UTF8String
		let utf8username = (username as NSString).UTF8String
		
		var passLen: UInt32 = 0
		var passBytes: UnsafeMutablePointer<Void> = nil
		var item: SecKeychainItemRef? = nil
		
		let result = SecKeychainFindGenericPassword(nil,
			UInt32(strlen(utf8account)), utf8account,
			UInt32(strlen(utf8username)), utf8username,
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
			let str = NSString(bytes: passBytes, length: Int(passLen), encoding: NSString.defaultCStringEncoding())
			return str as String?
		} else {
			return "" // if we have noErr but also no length, password is empty
		}
	}
	
	/// Saves password for username in account to Keychain. Returns true if the
	/// operation was successful, false otherwise.
	public func savePassword(password: String, forUsername username: String, inAccount account: String) -> Bool {
		let utf8username = (username as NSString).UTF8String
		let utf8password = (password as NSString).UTF8String
		let utf8account = (account as NSString).UTF8String
		
		let status = SecKeychainAddGenericPassword(nil,
			UInt32(strlen(utf8account)), utf8account,
			UInt32(strlen(utf8username)), utf8username,
			UInt32(strlen(utf8password)), utf8password,
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
		var passBytes: UnsafeMutablePointer<Void> = nil
		var item: SecKeychainItemRef? = nil

		let result = SecKeychainFindGenericPassword(nil,
			UInt32(strlen(utf8account)), utf8account,
			UInt32(strlen(utf8username)), utf8username,
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
		if NSString(bytes: passBytes, length: Int(passLen), encoding: NSString.defaultCStringEncoding()) == password {
			return true // It's the same password, ignore
		}
		
		let modificationResult = SecKeychainItemModifyContent(item!, nil, UInt32(strlen(utf8password)), utf8password)
		if modificationResult == noErr {
			return true
		}
		
		XULog("Failed to update keychain item for \(username) in \(account): \(modificationResult)")
		return false
	}
	
	
	private override init() {
		
	}
	
}
