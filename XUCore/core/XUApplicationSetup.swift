//
//  XUApplicationSetup.swift
//  XUCore
//
//  Created by Charlie Monroe on 11/21/15.
//  Copyright © 2015 Charlie Monroe Software. All rights reserved.
//

import Foundation

private func _URLForKey(key: String, inInfoDictionary infoDictionary: [String : AnyObject]) -> NSURL? {
	if let URLString = infoDictionary[key] as? String {
		let URL = NSURL(string: URLString)
		if URL == nil {
			// NSURL creation failed, report this to the user
			XULog("\(key) contains a nonnull value, but it doesn't seem to be a proper URL '\(URLString)'")
		}
		return URL
	}else{
		return nil
	}
}


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
	
	/// If isBetaBuild, this is the time interval after which the beta expires.
	/// By default, this is 7 days, but can be customized using XUBetaExpiration
	/// key. If you enter 0, the betas never expires.
	///
	/// @discussion - Only available on OS X.
	public let betaExpirationTimeInterval: NSTimeInterval
	
	/// Returns a NSURL object that contains a URL where exception report is sent
	/// by XUExceptionReporter. To turn on the XUExceptionCatcher, fill the URL
	/// under the key XUExceptionReporterURL in Info.plist. See XUExceptionReporter
	/// for more information.
	public let exceptionHandlerReportURL: NSURL?
	
	/// Returns true, if the current build is made for AppStore submission. To
	/// allow this, enter a boolean into Info.plist under key XUAppStoreBuild.
	/// True by default.
	///
	/// @discussion - Probably one of the alternatives would be to make an enum
	///				  of build types. Unfortunately, we can think of all of the
	///				  combinations of AppStore-Beta builds, which would not be
	///				  a nice solution. Hence these options are separated.
	public let isAppStoreBuild: Bool
	
	/// Returns true if the Info.plist contains a true boolean under the key
	/// XUBetaBuild. When true, the XUCore framework automatically handles
	/// beta expiration. False by default. See betaExpirationTimeInterval.
	public let isBetaBuild: Bool
	
	/// Returns true if the Dark Mode for menu bar and Dock is enabled. Will always
	/// return false on iOS.
	@available(OSX 10.0, *)
	@available(iOS, unavailable)
	public var isDarkModeEnabled: Bool {
		return NSUserDefaults.standardUserDefaults().stringForKey("AppleInterfaceStyle") == "Dark"
	}
	
	/// Returns true, if the app is being run in debug mode. Unlike Objective-C,
	/// where #if DEBUG macro can be applied, in Swift, this is a bit more
	/// complicated - edit the scheme of your project and add "--debug" to the
	/// arguments list to enable it.
	public let isRunningInDebugMode: Bool
	
	/// Number of items allowed for item-based trials. Enter into Info.plist as
	/// number under the key XUItemBasedTrialNumberOfItems. Default is 10.
	public let itemBasedTrialNumberOfItems: Int
	
	/// Name of the item that is up for the trial. E.g. "documents", "items",
	/// etc. Default is simply "items". You can change this using the key
	/// XUItemBasedTrialItemName. Note that the name must be plural and is
	/// passed to XULocalizedString(_) before being used.
	public let itemBasedTrialItemName: String
	
	/// An identifier of the app for message center. By default, 
	/// self.applicationIdentifier is used, but can be customized by defining
	/// XUMessageCenterAppIdentifier in Info.plist.
	public let messageCenterAppIdentifier: String
	
	/// Returns a NSURL object that contains a URL to the message feed handled
	/// by XUMessageCenter. To turn on the XUMessageCenter, fill the URL under
	/// the key XUMessageCenterFeedURL in Info.plist.
	public let messageCenterFeedURL: NSURL?
	
	/// Returns a NSURL object that contains a URL to a page, where you can
	/// purchase the app. Required by XUTrial. Fill the URL under the key
	/// XUPurchaseURL in Info.plist.
	public let purchaseURL: NSURL?
	
	/// Returns a NSURL object that contains a URL to your support page. Required
	/// by XUTrial. Fill the URL under the key XUSupportURL in Info.plist.
	public let supportURL: NSURL?
	
	/// Number of days allowed for time-based trials. Enter into Info.plist as
	/// number under the key XUTimeBasedTrialDays. Default is 14.
	public let timeBasedTrialDays: Int
	
	/// If the value is set to a non-nil value, XUCore will set up a trial. 
	/// The only allowed value at this moment is either "XUCore.XUTimeBasedTrial",
	/// or "XUCore.XUItemBasedTrial".
	/// Enter the value into Info.plist under the key XUTrialClassName. See 
	/// XUTimeBasedTrial class for more information.
	///
	/// @note: This is completely ignored if AppStoreBuild is set to true.
	public let trialClassName: String?
	
	/// Returns a NSURL object that contains a URL to a server which handles trial
	/// sessions. Required by XUTrial. See XUTrial for details. Fill the URL 
	/// under the key XUTrialSessionsURL in Info.plist.
	public let trialSessionsURL: NSURL?
	
	private override init() {
		let infoDictionary = NSBundle.mainBundle().infoDictionary ?? [ : ]
		
		if let appStoreBuild = infoDictionary["XUAppStoreBuild"] as? NSNumber {
			self.isAppStoreBuild = appStoreBuild.boolValue
		}else{
			self.isAppStoreBuild = true
		}
		
		if let betaBuild = infoDictionary["XUBetaBuild"] as? NSNumber {
			self.isBetaBuild = betaBuild.boolValue
		}else{
			self.isBetaBuild = false
		}
		
		if let betaExpirationTimeInterval = infoDictionary["XUBetaExpiration"] as? NSNumber where betaExpirationTimeInterval.doubleValue > 0.0 {
			self.betaExpirationTimeInterval = betaExpirationTimeInterval.doubleValue
		}else{
			self.betaExpirationTimeInterval = 7.0 * 24.0 * 3600.0
		}
		
		
		applicationBuildNumber = infoDictionary["CFBundleVersion"] as? String ?? "0"
		applicationVersionNumber = infoDictionary["CFBundleShortVersionString"] as? String ?? "1.0"
		
		exceptionHandlerReportURL = _URLForKey("XUExceptionReporterURL", inInfoDictionary: infoDictionary)
		messageCenterFeedURL = _URLForKey("XUMessageCenterFeedURL", inInfoDictionary: infoDictionary)
		purchaseURL = _URLForKey("XUPurchaseURL", inInfoDictionary: infoDictionary)
		supportURL = _URLForKey("XUSupportURL", inInfoDictionary: infoDictionary)
		trialSessionsURL = _URLForKey("XUTrialSessionsURL", inInfoDictionary: infoDictionary)
		
		
		let appIdentifier = NSBundle.mainBundle().bundleIdentifier ?? NSProcessInfo.processInfo().processName
		self.applicationIdentifier = appIdentifier
		self.messageCenterAppIdentifier = (infoDictionary["XUMessageCenterAppIdentifier"] as? String) ?? appIdentifier
		
		self.isRunningInDebugMode = NSProcessInfo.processInfo().arguments.contains("--debug")
		
		self.trialClassName = infoDictionary["XUTrialClassName"] as? String
		self.timeBasedTrialDays = (infoDictionary["XUTimeBasedTrialDays"] as? NSNumber)?.integerValue ?? 14
		
		self.itemBasedTrialNumberOfItems = (infoDictionary["XUItemBasedTrialNumberOfItems"] as? NSNumber)?.integerValue ?? 10
		self.itemBasedTrialItemName = (infoDictionary["XUItemBasedTrialItemName"] as? String) ?? "items"
		
		super.init()
	}
	
}

