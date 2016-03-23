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
#endif

/// Key for NSUserDefaults which contains a date when the block occurred.
private let XUMessageCenterAppBlockedDateDefaultsKey = "XUMessageCenterAppBlockedDate"

/// Key for NSUserDefaults which contains a boolean denoting whether the app is
/// blocked.
private let XUMessageCenterAppBlockedDefaultsKey = "XUMessageCenterAppBlocked"

/// Key for NSUserDefaults which contains an integer with the build number which
/// is the maximum blocked app version.
private let XUMessageCenterAppBlockedMaxVersionDefaultsKey = "XUMessageCenterAppBlockedMaxVersion"

/// Contains a NSNumber with the ID of the last message seen.
private let XUMessageCenterLastIDDefaultsKey = "XUMessageCenterLastID"


/// Defines which build types should receive the message.
@objc public enum XUMessageTarget: Int {
	
	/// All build types will receive the message.
	case All = 0
	
	/// Only apps that have AppStoreBuild true in XUApplicationSetup.
	case AppStore = 1
	
	/// Only apps that have AppStoreBuild false in XUApplicationSetup.
	case NonAppStore = 2
	
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
public class XUMessageCenter: NSObject {
	
	public static let sharedMessageCenter = XUMessageCenter()
	

	/// When set to true, the app was remotely blocked.
	public private(set) var appBlocked: Bool = false
	
	
	private typealias XUMessageDictionary = [String : AnyObject]
	
	private func _markMessageWithIDAsRead(messageID: Int) {
		// Save the message ID
		NSUserDefaults.standardUserDefaults().setInteger(messageID, forKey: XUMessageCenterLastIDDefaultsKey)
		NSUserDefaults.standardUserDefaults().synchronize()
	}
	
	private func _processActionsFromMessageDict(message: XUMessageDictionary, withMessageID messageID: Int) {
		guard let actions = message["XUActions"] as? [String : String] else {
			XULog("Invalid message \(message)")
			return
		}
		
		for (key, value) in actions {
			if key == "XUOpenURL" {
				guard let url = NSURL(string: value) else {
					XULog("Invalid URL string: \(value)")
					continue
				}
				
				#if os(iOS)
					UIApplication.sharedApplication().openURL(url)
				#else
					NSWorkspace.sharedWorkspace().openURL(url)
				#endif
			}else if key == "XUBlockApp" {
				self.appBlocked = false
				
				// Not yet - it will be in 24 hours, though
				guard let maxVersion = (message["XUMaxVersion"] as? String)?.integerValue else {
					XULog("Invalid message \(message)")
					continue
				}
				
				NSUserDefaults.standardUserDefaults().setBool(true, forKey: XUMessageCenterAppBlockedDefaultsKey)
				NSUserDefaults.standardUserDefaults().setObject(NSDate(), forKey: XUMessageCenterAppBlockedDateDefaultsKey)
				NSUserDefaults.standardUserDefaults().setInteger(maxVersion, forKey: XUMessageCenterAppBlockedMaxVersionDefaultsKey)
				
				let appName = NSProcessInfo.processInfo().processName
				let title = XULocalizedFormattedString("%@ will keep on working the next 24 hours, after which its functionality will be blocked. Please update %@ in order to keep it working.", appName, appName, inBundle: XUCoreBundle)
				
				#if os(iOS)
					let controller = UIAlertController(title: title, message: nil, preferredStyle: .Alert)
					controller.addAction(UIAlertAction(title: XULocalizedString("OK", inBundle: XUCoreBundle), style: .Default, handler: nil))
					UIApplication.sharedApplication().windows.first!.rootViewController?.presentViewController(controller, animated: true, completion: nil)
				#else
					let alert = NSAlert()
					alert.messageText = title
					alert.runModalOnMainThread()
				#endif
			}else{
				XULog("*** Unknown action \(key)")
			}
		}
		
		self._markMessageWithIDAsRead(messageID)
	}
	
	@objc private func _launchMessageCenter() {
		if XUApplicationSetup.sharedSetup.messageCenterFeedURL == nil {
			return // Ignore, if the feed URL is nil
		}
		
		XULog("Will be launching message center.")
		XU_PERFORM_BLOCK_ASYNC { () -> Void in
			self.checkForMessages()
		}
		
		if let blockedDate = NSUserDefaults.standardUserDefaults().objectForKey(XUMessageCenterAppBlockedDateDefaultsKey) as? NSDate {
			// We are more lenient now and give the user 24 hours to update
			if NSDate.timeIntervalSinceReferenceDate() - blockedDate.timeIntervalSinceReferenceDate < 24.0 * 3600.0 {
				return
			}
			
			self.appBlocked = NSUserDefaults.standardUserDefaults().boolForKey(XUMessageCenterAppBlockedDefaultsKey)
			let appBuildNumber = XUApplicationSetup.sharedSetup.applicationBuildNumber.integerValue
			let maxVersion = NSUserDefaults.standardUserDefaults().integerForKey(XUMessageCenterAppBlockedMaxVersionDefaultsKey)
			if self.appBlocked && maxVersion < appBuildNumber {
				self.appBlocked = false
				
				NSUserDefaults.standardUserDefaults().setBool(false, forKey: XUMessageCenterAppBlockedDefaultsKey)
				NSUserDefaults.standardUserDefaults().synchronize()
			}
		}
	}
	
	/// Checks for messages with the server. Must not be called from main thread.
	private func checkForMessages() {
		guard let feedURL = XUApplicationSetup.sharedSetup.messageCenterFeedURL else {
			return
		}
		
		guard let dict = NSDictionary(contentsOfURL: feedURL) else {
			return
		}

		let lastMessageID = NSUserDefaults.standardUserDefaults().integerForKey(XUMessageCenterLastIDDefaultsKey)
		let appBuildNumber = XUApplicationSetup.sharedSetup.applicationBuildNumber.integerValue
		
		let isAppStoreBuild = XUApplicationSetup.sharedSetup.isAppStoreBuild
		let appIdentifier = XUApplicationSetup.sharedSetup.applicationIdentifier
		
		guard let messages = dict[appIdentifier] as? [XUMessageDictionary] else {
			XULog("Either feed is invalid, or no messages are defined in the feed for \(appIdentifier)")
			return
		}
		
		for message in messages {
			guard let messageIDNumber = message["XUMessageID"] as? NSNumber else {
				XULog("Invalid message (missing ID) \(message)")
				continue
			}
			
			let messageID = messageIDNumber.integerValue
			if messageID <= lastMessageID {
				// Already seen it
				continue
			}
			
			guard let minVersion = (message["XUMinVersion"] as? NSNumber)?.integerValue else {
				XULog("Invalid message (missing min version) \(message)")
				continue
			}
			
			guard let maxVersion = (message["XUMaxVersion"] as? NSNumber)?.integerValue else {
				XULog("Invalid message (missing max version) \(message)")
				continue
			}
			
			if minVersion > appBuildNumber || maxVersion < appBuildNumber {
				continue
			}
			
			guard let targetNumber = message["XUTarget"] as? NSNumber else {
				XULog("Invalid message (missing target) \(message)")
				continue
			}
			
			guard let target = XUMessageTarget(rawValue: targetNumber.integerValue) else {
				XULog("Invalid message (unknown target) \(message)")
				continue
			}
			
			if (target == .AppStore && !isAppStoreBuild) || (target == .NonAppStore && isAppStoreBuild) {
				continue
			}
			
			let allowsIgnoringMessage = (message["XUCanIgnoreMessage"] as? NSNumber)?.boolValue ?? false
			
			var ignoreButtonTitle = XULocalizedString("Cancel", inBundle: XUCoreBundle)
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
				let alert = UIAlertController(title: messageText, message: message["XUDescription"] as? String, preferredStyle: .Alert)
				alert.addAction(UIAlertAction(title: XULocalizedString("OK", inBundle: XUCoreBundle), style: .Default, handler: { (_) -> Void in
					self._processActionsFromMessageDict(message, withMessageID: messageID)
				}))
				if allowsIgnoringMessage {
					alert.addAction(UIAlertAction(title: ignoreButtonTitle, style: .Cancel, handler: { (_) -> Void in
						self._markMessageWithIDAsRead(messageID)
					}))
				}

				XU_PERFORM_BLOCK_ON_MAIN_THREAD({ () -> Void in
					UIApplication.sharedApplication().windows.first!.rootViewController?.presentViewController(alert, animated: true, completion: nil)
				})
			#else
				let alert = NSAlert()
				alert.messageText = messageText
				alert.informativeText = (message["XUDescription"] as? String) ?? ""
				alert.addButtonWithTitle(XULocalizedString("OK", inBundle: XUCoreBundle))
				if allowsIgnoringMessage {
					alert.addButtonWithTitle(ignoreButtonTitle)
				}
				
				if alert.runModalOnMainThread() == NSAlertFirstButtonReturn {
					self._processActionsFromMessageDict(message, withMessageID: messageID)
				}else{
					self._markMessageWithIDAsRead(messageID)
				}
			#endif
			
			/* Only one alert per check. */
			break
		}
		
	}
		
	private override init() {
		super.init()
		
		// Do not allow FCMessageCenter in apps using XUCore.
		if NSClassFromString("FCMessageCenter") != nil {
			NSException(name: NSInternalInconsistencyException, reason: "Do not use FCMessageCenter.", userInfo: nil).raise()
		}
		
		#if os(iOS)
			let notificationName = UIApplicationDidFinishLaunchingNotification
		#else
			let notificationName = NSApplicationDidFinishLaunchingNotification
		#endif
		
		NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(XUMessageCenter._launchMessageCenter), name: notificationName, object: nil)
		
		// Repeat this every hour.
		NSTimer.scheduledTimerWithTimeInterval(3600.0, repeats: true) { (_) -> Void in
			XU_PERFORM_BLOCK_ASYNC({ () -> Void in
				self.checkForMessages()
			})
		}
	}
	
	
}
