//
//  XUApplicationSetup.swift
//  XUCore
//
//  Created by Charlie Monroe on 11/21/15.
//  Copyright © 2015 Charlie Monroe Software. All rights reserved.
//

import Foundation

/// This class contains several variables containing some of the information in
/// the main bundle's Info.plist. You can go through the variables and see what
/// information needs to be entered under which key to modify the app's behavior.
public class XUApplicationSetup: NSObject {
	
	/// Returns the shared setup.
	public static let sharedSetup = XUApplicationSetup()
	
	
	/// Returns the application build number - found under CFBundleVersion 
	/// in Info.plist. "0" by default.
	public let applicationBuildNumber: String
	
	/// This is an identifier of the app. By default, it is main bundle's bundle
	/// identifier and if it is null, process name is used.
	public let applicationIdentifier: String
	
	/// Returns the application version number - found under CFBundleShortVersionString
	/// in Info.plist. "1.0" by default.
	public let applicationVersionNumber: String
	
	/// Returns true, if the current build is made for AppStore submission. To
	/// allow this, enter a boolean into Info.plist under key XUAppStoreBuild.
	/// True by default.
	public let AppStoreBuild: Bool
	
	/// Returns true, if the app is being run in debug mode. Unlike Objective-C,
	/// where #if DEBUG macro can be applied, in Swift, this is a bit more 
	/// complicated - edit the scheme of your project and add "--debug" to the
	/// arguments list to enable it.
	public let debugMode: Bool
	
	/// An identifier of the app for message center. By default, 
	/// self.applicationIdentifier is used, but can be customized by defining
	/// XUMessageCenterAppIdentifier in Info.plist.
	public let messageCenterAppIdentifier: String
	
	/// Returns a NSURL object that contains a URL to the message feed handled
	/// by XUMessageCenter. To turn on the XUMessageCenter, fill the URL under
	/// the key XUMessageCenterFeedURL in Info.plist.
	public let messageCenterFeedURL: NSURL?
	
	
	private override init() {
		let infoDictionary = NSBundle.mainBundle().infoDictionary ?? [ : ]
		
		if let appStoreBuild = infoDictionary["XUAppStoreBuild"] as? NSNumber {
			self.AppStoreBuild = appStoreBuild.boolValue
		}else{
			self.AppStoreBuild = true
		}
		
		applicationBuildNumber = infoDictionary["CFBundleVersion"] as? String ?? "0"
		applicationVersionNumber = infoDictionary["CFBundleShortVersionString"] as? String ?? "1.0"
		
		if let messageFeedURLString = infoDictionary["XUMessageCenterFeedURL"] as? String {
			messageCenterFeedURL = NSURL(string: messageFeedURLString)
			if messageCenterFeedURL == nil {
				// NSURL creation failed, report this to the user
				XULog("XUMessageCenterFeedURL contains a nonnull value, but it doesn't seem to be a proper URL '\(messageFeedURLString)'")
			}
		}else{
			messageCenterFeedURL = nil
		}
		
		let appIdentifier = NSBundle.mainBundle().bundleIdentifier ?? NSProcessInfo.processInfo().processName
		self.applicationIdentifier = appIdentifier
		self.messageCenterAppIdentifier = (infoDictionary["XUMessageCenterAppIdentifier"] as? String) ?? appIdentifier
		
		self.debugMode = NSProcessInfo.processInfo().arguments.contains("--debug")
		
		super.init()
	}
	
}

