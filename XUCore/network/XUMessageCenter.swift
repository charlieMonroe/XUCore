//
//  XUMessageCenter.swift
//  XUCore
//
//  Created by Charlie Monroe on 11/21/15.
//  Copyright © 2015 Charlie Monroe Software. All rights reserved.
//

import Foundation

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
				let alert = NSAlert()
				alert.messageText = FCLocalizedFormattedString("\(appName) will keep on working the next 24 hours, after which its functionality will be blocked. Please update \(appName) in order to keep it working.")
				alert.runModalOnMainThread()
			}else{
				XULog("*** Unknown action \(key)")
			}
		}
		
		// Save the message ID
		NSUserDefaults.standardUserDefaults().setInteger(messageID, forKey: XUMessageCenterLastIDDefaultsKey)
		NSUserDefaults.standardUserDefaults().synchronize()
	}
	
	@objc private func _launchMessageCenter() {
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
		
		let isAppStoreBuild = XUApplicationSetup.sharedSetup.AppStoreBuild
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
			
			guard let minVersion = (message["XUMinVersion"] as? NSNumber)?.integerValue,
					maxVersion = (message["XUMaxVersion"] as? NSNumber)?.integerValue else {
				XULog("Invalid message (missing min or max version) \(message)")
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
			
			var ignoreButtonTitle = FCLocalizedString("Cancel")
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
			let alert = UIAlertView.alertWithTitle(message["XUMessage"], message: message["XUDescription"], handler: { (alertView: UIAlertView, clickedButton: Int) in
				if clickedButton == alertView.cancelButtonIndex {
					return
					
				}
				self._processActionsFromMessageDict(message, withMessageID: messageID)
				
				}, cancelButtonTitle: ignoreButtonTitle, andSecondButtonTitle: FCLocalizedString("OK"))
			dispatch_sync(dispatch_get_main_queue(),{	alert.show
				
			})
				/* Only one alert per check. */
				break
			#else
				let alert = NSAlert()
				alert.messageText = messageText
				alert.informativeText = (message["XUDescription"] as? String) ?? ""
				alert.addButtonWithTitle(FCLocalizedString("OK"))
				if allowsIgnoringMessage {
					alert.addButtonWithTitle(ignoreButtonTitle)
				}
				
				if alert.runModalOnMainThread() == NSAlertFirstButtonReturn {
					self._processActionsFromMessageDict(message, withMessageID: messageID)
				}
				
				/* Only one alert per check. */
				break
			#endif
		}
		
	}
		
	private override init() {
		super.init()
		
		#if os(iOS)
		#else
			let notificationName = NSApplicationDidFinishLaunchingNotification
		#endif
		
		NSNotificationCenter.defaultCenter().addObserver(self, selector: "_launchMessageCenter", name: notificationName, object: nil)
		
		// Repeat this every hour.
		NSTimer.scheduledTimerWithTimeInterval(3600.0, repeats: true) { (_) -> Void in
			XU_PERFORM_BLOCK_ASYNC({ () -> Void in
				self.checkForMessages()
			})
		}
	}
	
	
}
