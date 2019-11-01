//
//  XUMessageCenter.swift
//  XUCore
//
//  Created by Charlie Monroe on 11/21/15.
//  Copyright © 2015 Charlie Monroe Software. All rights reserved.
//

import Foundation
import XUCore

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
		nonmutating set {
			self.set(value: newValue, forKey: .AppBlockedDate)
		}
	}
	
	var appBlockedMaxVersion: Int {
		get {
			return self.integer(for: .AppBlockedMaxVersion)
		}
		nonmutating set {
			self.set(integer: newValue, forKey: .AppBlockedMaxVersion)
		}
	}
	
	var isAppBlocked: Bool {
		get {
			return self.boolean(for: .AppBlocked)
		}
		nonmutating set {
			self.set(boolean: newValue, forKey: .AppBlocked)
		}
	}
	
	var lastMessageID: Int {
		get {
			return self.integer(for: .LastMessageID)
		}
		nonmutating set {
			self.set(integer: newValue, forKey: .LastMessageID)
		}
	}
	
}

@available(iOSApplicationExtension, unavailable)
@available(macCatalystApplicationExtension, unavailable)
protocol XUMessageCenterAction {
	init?(value: String)
	func performAction(with message: XUMessageCenter.Message)
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
@available(iOSApplicationExtension, unavailable)
@available(macCatalystApplicationExtension, unavailable)
public class XUMessageCenter {
	
	public static let shared = XUMessageCenter()
	
	struct BlockApplicationAction: XUMessageCenterAction {
		
		init(value: String) {
			// We ignore the value
		}
		
		func performAction(with message: XUMessageCenter.Message) {
			XUMessageCenter.shared.isAppBlocked = false
			
			// Not yet - it will be in 24 hours, though.
			let maxVersion = message.maximumBuildNumber
			XUPreferences.shared.perform(andSynchronize: { (prefs) in
				prefs.isAppBlocked = true
				prefs.appBlockedDate = Date()
				prefs.appBlockedMaxVersion = maxVersion
			})
			
			let appName = ProcessInfo.processInfo.processName
			let title = XULocalizedFormattedString("%@ will keep on working the next 24 hours, after which its functionality will be blocked. Please update %@ in order to keep it working.", appName, appName, inBundle: .core)
			
			DispatchQueue.main.syncOrNow {
				#if canImport(UIKit)
					let controller = UIAlertController(title: title, message: nil, preferredStyle: .alert)
					controller.addAction(UIAlertAction(title: XULocalizedString("OK", inBundle: .core), style: .default, handler: nil))
					UIApplication.shared.windows.first!.rootViewController?.present(controller, animated: true, completion: nil)
				#else
					let alert = NSAlert()
					alert.messageText = title
					alert.runModal()
				#endif
			}
		}
		
	}
	
	/// A structure encapsulating the message.
	struct Message {
		
		/// Actions.
		let actions: [XUMessageCenterAction]
		
		/// If true, the user is presented with a cancel button.
		let allowsIgnoringMessage: Bool
		
		/// Ignore button title.
		let customIgnoreButtonTitle: String?
		
		/// ID of the message.
		let id: Int

		/// Informative text (subtitle).
		let informativeText: String?
		
		/// Maximum build number for which is this message.
		let maximumBuildNumber: Int
		
		/// Actual message.
		let message: String
		
		/// Minimum build number for which is this message.
		let minimumBuildNumber: Int
		
		/// The original dictionary.
		let rawDictionary: XUJSONDictionary
		
		/// Target.
		let target: Target
		
		
		/// Returns a title for an ignore button. Takes into account custom title.
		/// Asserts that ignore button is allowed.
		var ignoreButtonTitle: String {
			XUAssert(self.allowsIgnoringMessage)
			return self.customIgnoreButtonTitle ?? XULocalizedString("Cancel", inBundle: .core)
		}
		
		init?(dictionary: XUJSONDictionary) {
			guard let messageID = dictionary["XUMessageID"] as? Int else {
				XULog("Invalid message (missing ID) \(dictionary)")
				return nil
			}
			
			guard let minVersion = dictionary["XUMinVersion"] as? Int, let maxVersion = dictionary["XUMaxVersion"] as? Int else {
				XULog("Invalid message (missing min or max version) \(dictionary)")
				return nil
			}
			
			guard let targetNumber = dictionary["XUTarget"] as? Int, let target = Target(rawValue: targetNumber) else {
				XULog("Invalid message (missing or invalid target) \(dictionary)")
				return nil
			}
			
			guard let messageText = dictionary["XUMessage"] as? String else {
				XULog("Invalid message (missing message text) \(dictionary)")
				return nil
			}

			self.rawDictionary = dictionary
			self.allowsIgnoringMessage = dictionary.boolean(forKey: "XUCanIgnoreMessage")
			self.customIgnoreButtonTitle = dictionary["XUIgnoreButtonTitle"] as? String
			self.id = messageID
			self.informativeText = dictionary["XUDescription"] as? String
			self.maximumBuildNumber = maxVersion
			self.message = messageText
			self.minimumBuildNumber = minVersion
			self.target = target
			
			guard let actionDicts = dictionary["XUActions"] as? [String : String] else {
				XULog("Message \(messageID) is has no actions: \(dictionary)")
				self.actions = []
				return
			}
			
			let actions = actionDicts.compactMap { (key, value) -> XUMessageCenterAction? in
				switch key {
				case "XUOpenURL":
					return OpenURLAction(value: value)
				case "XUBlockApp":
					return BlockApplicationAction(value: value)
				default:
					XULog("*** Unknown action \(key)")
					return nil
				}
			}
			
			self.actions = actions
		}
		
	}
	
	struct OpenURLAction: XUMessageCenterAction {
		
		let url: URL
		
		init?(value: String) {
			guard let url = URL(value) else {
				XULog("Invalid URL string: \(value)")
				return nil
			}
			
			self.url = url
		}
		
		func performAction(with message: XUMessageCenter.Message) {
			#if canImport(UIKit)
				UIApplication.shared.open(self.url, options: [:], completionHandler: nil)
			#else
				NSWorkspace.shared.open(self.url)
			#endif
		}
		
	}
	
	/// Defines which build types should receive the message.
	public enum Target: Int {
		
		/// All build types will receive the message.
		case all = 0
		
		/// Only apps that have AppStoreBuild true in XUApplicationSetup.
		case appStore = 1
		
		/// Only apps that have AppStoreBuild false in XUApplicationSetup.
		case nonAppStore = 2
		
	}

	

	/// When set to true, the app was remotely blocked.
	public private(set) var isAppBlocked: Bool = false
	
	
	private func _markMessageAsRead(_ message: Message) {
		// Save the message ID
		XUPreferences.shared.perform(andSynchronize: { (prefs) in
			prefs.lastMessageID = message.id
		})
	}
	
	private func _processActions(from message: Message) {
		message.actions.forEach({ $0.performAction(with: message) })
		self._markMessageAsRead(message)
	}
	
	@objc private func _launchMessageCenter() {
		if XUAppSetup.messageCenterFeedURL == nil {
			return // Ignore, if the feed URL is nil
		}
		
		XULog("Will be launching message center.")
		DispatchQueue.global(qos: .default).async {
			self.checkForMessages()
		}
		
		if let blockedDate = XUPreferences.shared.appBlockedDate {
			// We are more lenient now and give the user 24 hours to update
			if Date.timeIntervalSinceReferenceDate - blockedDate.timeIntervalSinceReferenceDate < XUTimeInterval.day {
				XUPreferences.shared.appBlockedDate = nil
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
			
			if self.isAppBlocked {
				XULog("The app is blocked.")
			}
		}
	}
	
	/// Checks for messages with the server. Must not be called from main thread.
	private func checkForMessages() {
		guard let feedURL = XUAppSetup.messageCenterFeedURL else {
			XULog("Missing feed URL.")
			return
		}
		
		guard let dict = NSDictionary(contentsOf: feedURL) else {
			XULog("Can't load feed dictionary.")
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
		
		XULog("Checking for messages.")
		
		for dictionary in messages {
			guard let message = Message(dictionary: dictionary) else {
				continue
			}
			
			if message.id <= lastMessageID {
				// Already seen it
				XULog("Ignoring message \(message.id) as it's already been seen (last ID: \(lastMessageID)).")
				continue
			}
			
			if message.minimumBuildNumber > appBuildNumber || message.maximumBuildNumber < appBuildNumber {
				continue
			}
			
			if (message.target == .appStore && !isAppStoreBuild) || (message.target == .nonAppStore && isAppStoreBuild) {
				continue
			}
			
			DispatchQueue.main.syncOrNow {
				self._showMessage(with: message)
			}
			
			/* Only one alert per check. */
			break
		}
		
	}
	
	
	private func _showMessage(with message: Message) {
		// We should display this message!
		#if canImport(UIKit)
			let alert = UIAlertController(title: message.message, message: message.informativeText, preferredStyle: .alert)
			alert.addAction(UIAlertAction(title: XULocalizedString("OK", inBundle: .core), style: .default, handler: { (_) -> Void in
				self._processActions(from: message)
			}))
			if message.allowsIgnoringMessage {
				alert.addAction(UIAlertAction(title: message.ignoreButtonTitle, style: .cancel, handler: { (_) -> Void in
					self._markMessageAsRead(message)
				}))
			}
		
			UIApplication.shared.windows.first!.rootViewController?.present(alert, animated: true, completion: nil)
		#else
			let alert = NSAlert()
			alert.messageText = message.message
			alert.informativeText = message.informativeText ?? ""
			alert.addButton(withTitle: XULocalizedString("OK", inBundle: .core))
			if message.allowsIgnoringMessage {
				alert.addButton(withTitle: message.ignoreButtonTitle)
			}
		
			if alert.runModal() == .alertFirstButtonReturn {
				self._processActions(from: message)
			} else {
				self._markMessageAsRead(message)
			}
		#endif
	}
		
	private init() {
		#if canImport(UIKit)
			let notificationName = UIApplication.didFinishLaunchingNotification
		#else
			let notificationName = NSApplication.didFinishLaunchingNotification
		#endif
		
		NotificationCenter.default.addObserver(self, selector: #selector(XUMessageCenter._launchMessageCenter), name: notificationName, object: nil)
		
		// Repeat this every hour.
		_ = Timer.scheduledTimer(timeInterval: XUTimeInterval.hour, repeats: true) { (_) -> Void in
			DispatchQueue.global(qos: .default).async(execute: { () -> Void in
				self.checkForMessages()
			})
		}
	}
	
	
}
