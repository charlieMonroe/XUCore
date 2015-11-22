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
	
	/// Returns true, if the current build is made for AppStore submission. To
	/// allow this, enter a boolean into Info.plist under key XUAppStoreBuild.
	/// True by default.
	public let AppStoreBuild: Bool
	
	/// Returns true, if the app is being run in debug mode. Unlike Objective-C,
	/// where #if DEBUG macro can be applied, in Swift, this is a bit more 
	/// complicated - edit the scheme of your project and add "--debug" to the
	/// arguments list to enable it.
	public let debugMode: Bool
	
	/// Returns a NSURL object that contains a URL where exception report is sent
	/// by XUExceptionReporter. To turn on the XUExceptionCatcher, fill the URL
	/// under the key XUExceptionReporterURL in Info.plist. See XUExceptionReporter
	/// for more information.
	public let exceptionHandlerReportURL: NSURL?
	
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
	/// The only allowed value at this moment is "XUCore.XUTimeBasedTrial". 
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
			self.AppStoreBuild = appStoreBuild.boolValue
		}else{
			self.AppStoreBuild = true
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
		
		self.debugMode = NSProcessInfo.processInfo().arguments.contains("--debug")
		
		self.trialClassName = infoDictionary["XUTrialClassName"] as? String
		self.timeBasedTrialDays = (infoDictionary["XUTimeBasedTrialDays"] as? NSNumber)?.integerValue ?? 14
		
		super.init()
	}
	
}

