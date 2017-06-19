//
//  XUMessageCenter.swift
//  XUCore
//
//  Created by Charlie Monroe on 11/21/15.
//  Copyright © 2015 Charlie Monroe Software. All rights reserved.
//

import Foundation

#if os(iOS)
	import UIKit
#else
	import AppKit
#endif

private extension XUPreferences.Key {

	/// Key for XUPreferences which contains a date when the block occurred.
	static let AppBlockedDate = XUPreferences.Key(rawValue: "XUMessageCenterAppBlockedDate")
	
	/// Key for XUPreferences which contains a boolean denoting whether the app is
	/// blocked.
	static let AppBlocked = XUPreferences.Key(rawValue: "XUMessageCenterAppBlocked")
	
	/// Key for XUPreferences which contains an integer with the build number which
	/// is the maximum blocked app version.
	static let AppBlockedMaxVersion = XUPreferences.Key(rawValue: "XUMessageCenterAppBlockedMaxVersion")
	
	/// Contains a NSNumber with the ID of the last message seen.
	static let LastMessageID = XUPreferences.Key(rawValue: "XUMessageCenterLastID")
	
}

private extension XUPreferences {
	
	var appBlockedDate: Date? {
		get {
			return self.value(for: .AppBlockedDate)
		}
		set {
			self.set(value: newValue, forKey: .AppBlockedDate)
		}
	}
	
	var appBlockedMaxVersion: Int {
		get {
			return self.integer(for: .AppBlockedMaxVersion)
		}
		set {
			self.set(integer: newValue, forKey: .AppBlockedMaxVersion)
		}
	}
	
	var isAppBlocked: Bool {
		get {
			return self.boolean(for: .AppBlocked)
		}
		set {
			self.set(boolean: newValue, forKey: .AppBlocked)
		}
	}
	
	var lastMessageID: Int {
		get {
			return self.integer(for: .LastMessageID)
		}
		set {
			self.set(integer: newValue, forKey: .LastMessageID)
		}
	}
	
}


/// Defines which build types should receive the message.
public enum XUMessageTarget: Int {
	
	/// All build types will receive the message.
	case all = 0
	
	/// Only apps that have AppStoreBuild true in XUApplicationSetup.
	case appStore = 1
	
	/// Only apps that have AppStoreBuild false in XUApplicationSetup.
	case nonAppStore = 2
	
}


/// This class automatically pulls down a property list from the server which
/// contains messages for the users and displays them accordingly. The center
/// gets instantiated automatically on +load.
///
/// The URL of message feed needs to be defined in Info.plist - see XUApplicationSetup.
///
/// The URL must lead to a Property list file which is a dictionary that with 
/// the following structure:
///
/// AppID -		Message1
///				Message2
///				...
/// AppID2 -	Message1
///				...
/// ...
///
///
/// I.e. each entry of the root dictionary object contains an array of messages.
/// These arrays are under keys which usually are the app's bundle identifier, 
/// but can be customized - see XUApplicationSetup's messageFeedAppIdentifier.
///
/// Each message is a dictionary with the following properties:
///
/// XUMessageID - NSNumber containing a message ID that is unique to each message
///					for that particular app.
/// XUMessage - The actual message (mandatory).
/// XUDescription - Message details (optional).
/// XUMaxVersion - maximum build number of the app to display the message to.
/// XUMinVersion - minimum build number of the app to display the message to.
/// XUTarget - target of the message. See XUMessageTarget enum and use the raw 
///				values.
/// XUCanIgnoreMessage - optionally, set this to true. If true, the user is presented
///				with a Cancel button.
/// XUIgnoreButtonTitle - optionally, you can provide your own ignore button title.
///				It is Cancel by default.
/// XUActions: dictionary of actions which are:
///		- XUOpenURL - the value must contains a string with the URL.
///		- XUBlockApp - the value must be a string, but can contain anything.
///
public class XUMessageCenter {
	
	public static let shared = XUMessageCenter()
	

	/// When set to true, the app was remotely blocked.
	public private(set) var isAppBlocked: Bool = false
	
	private func _markMessageWithIDAsRead(_ messageID: Int) {
		// Save the message ID
		XUPreferences.shared.perform(andSynchronize: { (prefs) in
			prefs.lastMessageID = messageID
		})
	}
	
	private func _processActions(from message: XUJSONDictionary, withMessageID messageID: Int) {
		guard let actions = message["XUActions"] as? [String : String] else {
			XULog("Invalid message \(message)")
			return
		}
		
		for (key, value) in actions {
			if key == "XUOpenURL" {
				guard let url = URL(string: value) else {
					XULog("Invalid URL string: \(value)")
					continue
				}
				
				#if os(iOS)
					UIApplication.shared.openURL(url)
				#else
					NSWorkspace.shared.open(url)
				#endif
			} else if key == "XUBlockApp" {
				self.isAppBlocked = false
				
				// Not yet - it will be in 24 hours, though
				guard let maxVersion = (message["XUMaxVersion"] as? String)?.integerValue else {
					XULog("Invalid message \(message)")
					continue
				}
				
				XUPreferences.shared.perform(andSynchronize: { (prefs) in
					prefs.isAppBlocked = true
					prefs.appBlockedDate = Date()
					prefs.appBlockedMaxVersion = maxVersion
				})

				let appName = ProcessInfo.processInfo.processName
				let title = XULocalizedFormattedString("%@ will keep on working the next 24 hours, after which its functionality will be blocked. Please update %@ in order to keep it working.", appName, appName, inBundle: XUCoreFramework.bundle)
				
				#if os(iOS)
					let controller = UIAlertController(title: title, message: nil, preferredStyle: .alert)
					controller.addAction(UIAlertAction(title: XULocalizedString("OK", inBundle: XUCoreFramework.bundle), style: .default, handler: nil))
					UIApplication.shared.windows.first!.rootViewController?.present(controller, animated: true, completion: nil)
				#else
					let alert = NSAlert()
					alert.messageText = title
					alert.runModalOnMainThread()
				#endif
			} else {
				XULog("*** Unknown action \(key)")
			}
		}
		
		self._markMessageWithIDAsRead(messageID)
	}
	
	@objc private func _launchMessageCenter() {
		if XUAppSetup.messageCenterFeedURL == nil {
			return // Ignore, if the feed URL is nil
		}
		
		XULog("Will be launching message center.")
		XU_PERFORM_BLOCK_ASYNC { () -> Void in
			self.checkForMessages()
		}
		
		if let blockedDate = XUPreferences.shared.appBlockedDate {
			// We are more lenient now and give the user 24 hours to update
			if Date.timeIntervalSinceReferenceDate - blockedDate.timeIntervalSinceReferenceDate < XUTimeInterval.day {
				return
			}
			
			self.isAppBlocked = XUPreferences.shared.isAppBlocked
			let appBuildNumber = XUAppSetup.applicationBuildNumber.integerValue
			let maxVersion = XUPreferences.shared.appBlockedMaxVersion
			if self.isAppBlocked && maxVersion < appBuildNumber {
				self.isAppBlocked = false
				
				XUPreferences.shared.perform(andSynchronize: { (prefs) in
					prefs.isAppBlocked = false
				})
			}
		}
	}
	
	/// Checks for messages with the server. Must not be called from main thread.
	private func checkForMessages() {
		guard let feedURL = XUAppSetup.messageCenterFeedURL else {
			return
		}
		
		guard let dict = NSDictionary(contentsOf: feedURL) else {
			return
		}

		let lastMessageID = XUPreferences.shared.lastMessageID
		let appBuildNumber = XUAppSetup.applicationBuildNumber.integerValue
		
		let isAppStoreBuild = XUAppSetup.isAppStoreBuild
		let appIdentifier = XUAppSetup.applicationIdentifier.deleting(suffix: "-setapp")
		
		guard let messages = dict[appIdentifier] as? [XUJSONDictionary] else {
			XULog("Either feed is invalid, or no messages are defined in the feed for \(appIdentifier)")
			return
		}
		
		for message in messages {
			guard let messageID = message["XUMessageID"] as? Int else {
				XULog("Invalid message (missing ID) \(message)")
				continue
			}
			
			if messageID <= lastMessageID {
				// Already seen it
				continue
			}
			
			guard let minVersion = message["XUMinVersion"] as? Int else {
				XULog("Invalid message (missing min version) \(message)")
				continue
			}
			
			guard let maxVersion = message["XUMaxVersion"] as? Int else {
				XULog("Invalid message (missing max version) \(message)")
				continue
			}
			
			if minVersion > appBuildNumber || maxVersion < appBuildNumber {
				continue
			}
			
			guard let targetNumber = message["XUTarget"] as? Int else {
				XULog("Invalid message (missing target) \(message)")
				continue
			}
			
			guard let target = XUMessageTarget(rawValue: targetNumber) else {
				XULog("Invalid message (unknown target) \(message)")
				continue
			}
			
			if (target == .appStore && !isAppStoreBuild) || (target == .nonAppStore && isAppStoreBuild) {
				continue
			}
			
			let allowsIgnoringMessage = (message["XUCanIgnoreMessage"] as? Bool) ?? false
			
			var ignoreButtonTitle = XULocalizedString("Cancel", inBundle: XUCoreFramework.bundle)
			if allowsIgnoringMessage {
				if let customIgnoreButtonTitle = message["XUIgnoreButtonTitle"] as? String {
					ignoreButtonTitle = customIgnoreButtonTitle
				}
			}
			
			guard let messageText = message["XUMessage"] as? String else {
				XULog("Invalid message (missing message text) \(message)")
				continue
			}
			
			// We should display this message!
			#if os(iOS)
				let alert = UIAlertController(title: messageText, message: message["XUDescription"] as? String, preferredStyle: .alert)
				alert.addAction(UIAlertAction(title: XULocalizedString("OK", inBundle: XUCoreFramework.bundle), style: .default, handler: { (_) -> Void in
					self._processActions(from: message, withMessageID: messageID)
				}))
				if allowsIgnoringMessage {
					alert.addAction(UIAlertAction(title: ignoreButtonTitle, style: .cancel, handler: { (_) -> Void in
						self._markMessageWithIDAsRead(messageID)
					}))
				}

				XU_PERFORM_BLOCK_ON_MAIN_THREAD({ () -> Void in
					UIApplication.shared.windows.first!.rootViewController?.present(alert, animated: true, completion: nil)
				})
			#else
				let alert = NSAlert()
				alert.messageText = messageText
				alert.informativeText = (message["XUDescription"] as? String) ?? ""
				alert.addButton(withTitle: XULocalizedString("OK", inBundle: XUCoreFramework.bundle))
				if allowsIgnoringMessage {
					alert.addButton(withTitle: ignoreButtonTitle)
				}
				
				if alert.runModalOnMainThread() == NSApplication.ModalResponse.alertFirstButtonReturn {
					self._processActions(from: message, withMessageID: messageID)
				}else{
					self._markMessageWithIDAsRead(messageID)
				}
			#endif
			
			/* Only one alert per check. */
			break
		}
		
	}
		
	private init() {
		#if os(iOS)
			let notificationName = NSNotification.Name.UIApplicationDidFinishLaunching
		#else
			let notificationName = NSApplication.didFinishLaunchingNotification
		#endif
		
		NotificationCenter.default.addObserver(self, selector: #selector(XUMessageCenter._launchMessageCenter), name: notificationName, object: nil)
		
		// Repeat this every hour.
		_ = Timer.scheduledTimer(timeInterval: XUTimeInterval.hour, repeats: true) { (_) -> Void in
			XU_PERFORM_BLOCK_ASYNC({ () -> Void in
				self.checkForMessages()
			})
		}
	}
	
	
}
