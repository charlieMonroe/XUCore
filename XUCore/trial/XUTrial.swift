//
//  XUTrial.swift
//  XUCore
//
//  Created by Charlie Monroe on 11/22/15.
//  Copyright © 2015 Charlie Monroe Software. All rights reserved.
//

import Foundation

/// The base class for trials. You need to modify Info.plist to include the
/// following URLs:
///
/// - purchaseURL - URL that leads to the purchase page. Be it in the AppStore, 
///					or elsewhere.
/// - supportURL - URL that leads to your support page.
/// - trialSessionsURL - a URL that handles the trial sessions. It needs to be
///						able to handle both GET and POST requests:
///
///		- GET: used to retrieve a list of trial sessions per host. The host ID
///				is passed under "key" argument. The response needs to be a JSON
///				array of dictionaries each of which contains the following:
///				- app_identifier - identifier of the app
///				- id - ID of the trial. Usually a number, but can be any string.
///				- created_at - time when the trial was created. A string in the
///							following format: 2013-10-31T00:00:00+00:00
///		- POST: used to create a new trial session. Two arguments are passed in
///				the URL (NOT the HTTP body!). "key" contains the host identifier
///				and "app" contains the app identifier.
///
public class XUTrial: NSObject {
	
	/// Returns the shared trial. Will be nil when trial is not enabled, or
	/// AppStoreBuild is active.
	public static let sharedTrial: XUTrial? = {
		let setup = XUApplicationSetup.sharedSetup
		if setup.AppStoreBuild {
			return nil
		}
		
		guard let className = setup.trialClassName else {
			return nil
		}
		
		guard let trialClass = NSClassFromString(className) as? XUTrial.Type else {
			return nil
		}
		
		guard let purchaseURL = setup.purchaseURL, supportURL = setup.supportURL, trialSessionsURL = setup.trialSessionsURL else {
			XULog("****WARNING**** - trying to create XUTrial, but one of the required URLs is not defined.")
			return nil
		}
		
		if NSClassFromString("FCTrial") != nil {
			NSException(name: NSInternalInconsistencyException, reason: "Do not use FCTrial in combination with XUCore.", userInfo: nil).raise()
			return nil
		}
		
		return trialClass.init(purchaseURL: purchaseURL, supportURL: supportURL, andTrialSessionsURL: trialSessionsURL)
	}()
	
	private var _wasFirstRun: Bool = false
	private var _secondsLeft: NSTimeInterval = 0
	
	private let purchaseURL: NSURL
	private let supportURL: NSURL
	private let trialSessionsURL: NSURL
	
	private func _innerInit() {
		let trialURL = NSURL(string: self.trialSessionsURL.absoluteString + "?key=\(self._sessionIdentifier)")!
		
		guard let data = NSData(contentsOfURL: trialURL) else {
			NSNotificationCenter.defaultCenter().addObserver(self, selector: "_warnAboutNoInternetConnection", name: NSApplicationDidFinishLaunchingNotification, object: nil)
			return
		}
		
		guard let apps = (try? NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions())) as? [[String : String]] else {
			NSNotificationCenter.defaultCenter().addObserver(self, selector: "_warnAboutNoInternetConnection", name: NSApplicationDidFinishLaunchingNotification, object: nil)
			return
		}
		
		let identifier = XUApplicationSetup.sharedSetup.applicationIdentifier
		guard let appDict = apps.find({ $0["app_identifier"] == identifier }) else {
			if self._registerWithTrialServer() {
				_secondsLeft = NSTimeInterval(XUApplicationSetup.sharedSetup.timeBasedTrialDays) * (24.0 * 3600.0)
				_wasFirstRun = true
				NSTimer.scheduledTimerWithTimeInterval(_secondsLeft, target: self, selector: "_showFirstRunAlert", userInfo: nil, repeats: false)
			}else{
				NSNotificationCenter.defaultCenter().addObserver(self, selector: "_warnAboutNoInternetConnection", name: NSApplicationDidFinishLaunchingNotification, object: nil)
			}
			return
		}
		
		guard let trialID = appDict["id"], var dateString = appDict["created_at"] else {
			NSException(name: NSInternalInconsistencyException, reason: "The appDict doesn't contain trial ID or created_at.", userInfo: nil).raise()
			return
		}
		
		XULog(trialID)
		
		dateString = dateString.stringByReplacingOccurrencesOfString("T", withString: " ")
		dateString = dateString.stringByReplacingOccurrencesOfString("+", withString: " +")
		
		let date = NSDate(string: dateString) ?? NSDate()
		let now = NSDate()
		let difference = now.timeIntervalSinceDate(date)
		
		_secondsLeft = NSTimeInterval(XUApplicationSetup.sharedSetup.timeBasedTrialDays) * (24.0 * 3600.0) - abs(difference)
		
		if _secondsLeft > 0.0 {
			NSTimer.scheduledTimerWithTimeInterval(_secondsLeft, target: self, selector: "_trialExpired", userInfo: nil, repeats: false)
		}else{
			XUForceLog("trial expired, session identifier \(self._sessionIdentifier), trial ID \(trialID)")
			self._trialExpiredWithTrialID(trialID)
		}
	}
	
	/// Opens a purchase URL.
	private func _openPurchaseURL() {
		NSWorkspace.sharedWorkspace().openURL(self.purchaseURL)
	}
	
	/// Opens a support URL.
	private func _openSupportURL() {
		NSWorkspace.sharedWorkspace().openURL(self.supportURL)
	}
	
	/// Registers the app with the trial server.
	private func _registerWithTrialServer() -> Bool {
		let identifier = XUApplicationSetup.sharedSetup.applicationIdentifier.stringByEncodingIllegalURLCharacters
		let URL = NSURL(string: self.trialSessionsURL.absoluteString + "?key=\(self._sessionIdentifier)&app=\(identifier)")!
		let request = NSMutableURLRequest(URL: URL)
		request.HTTPMethod = "POST"
		
		var genericResponse: NSURLResponse?
		_ = try? NSURLConnection.sendSynchronousRequest(request, returningResponse: &genericResponse)
		
		guard let response = genericResponse as? NSHTTPURLResponse else {
			return false
		}
		
		return response.statusCode >= 200 && response.statusCode < 300
	}
	
	/// Returns a unique identifier of this computer and user.
	private var _sessionIdentifier: String {
		let macAddress = XUHardwareInfo.sharedHardwareInfo.serialNumber.MD5Digest
		let sessionIdentifier = macAddress + NSUserName().MD5Digest
		return sessionIdentifier
	}
	
	/// Creates short 1-hour trial, in case there is no Internet connection.
	private func _shortTrial() {
		// 1 hour
		_secondsLeft = 3600.0
		NSTimer.scheduledTimerWithTimeInterval(_secondsLeft, target: self, selector: "_trialExpired", userInfo: nil, repeats: false)
	}
	
	/// Shows an alert when isFirstRun is true.
	@objc private func _showFirstRunAlert() {
		let appName = NSProcessInfo.processInfo().processName
		self._showTrialAlertWithMessage(XULocalizedFormattedString("Thanks for trying out %@! You may use it for 15 days now without any limitations. After the trial period expires, you'll need to purchase a copy of %@.", appName, appName))
	}
	
	/// Displays an alert with custom message about the trial.
	private func _showTrialAlertWithMessage(message: String) {
		let alert = NSAlert()
		alert.messageText = message
		alert.informativeText = XULocalizedString("Enjoy our software! If you have any questions or run into any bugs, feel free to ask us at our support page \(self.supportURL.absoluteString)")
		alert.addButtonWithTitle(XULocalizedString("Continue"))
		alert.addButtonWithTitle(XULocalizedString("Purchase..."))

		let alertResult = alert.runModal()
		if alertResult == NSAlertFirstButtonReturn {
			// Continue
			return
		}else if alertResult == NSAlertSecondButtonReturn {
			// Purchase
			self._openPurchaseURL()
		}
	}
	
	/// Calls _trialExpiredWithTrialID with nil trialID. Necessary for 
	/// notifications and timer firing.
	@objc private func _trialExpired() {
		self._trialExpiredWithTrialID(nil)
	}
	
	/// Notifies the user that the trial has expired. Trial ID is included.
	private func _trialExpiredWithTrialID(trialID: String?) {
		XUForceLog("trial expired, session identifier \(self._sessionIdentifier)")
		
		let appName = NSProcessInfo.processInfo().processName
		let alert = NSAlert()
		alert.messageText = XULocalizedFormattedString("Thanks for trying out %@! You've been using it %li days now. To continue using %@ you need to purchase a copy.", appName, XUApplicationSetup.sharedSetup.timeBasedTrialDays, appName)
		alert.informativeText = XULocalizedFormattedString("You will be taken to a page where you'll be able to buy a copy. If you're still not sure if %@ is right for you and have some questions, contact us.%@", appName, trialID != nil ? " (Trial ID: \(trialID!))" : "")
		alert.addButtonWithTitle(XULocalizedString("Purchase..."))
		alert.addButtonWithTitle(XULocalizedString("I'm Still Not Sure"))
		
		let result = alert.runModal()
		if result == NSAlertFirstButtonReturn {
			self._openPurchaseURL()
		}else if result == NSAlertSecondButtonReturn {
			self._openSupportURL()
		}
		
		exit(0)
	}
	
	/// Warns the user that there is not internet connection. Under such 
	/// circumstances, the app exits in an hour.
	@objc private func _warnAboutNoInternetConnection() {
		let alert = NSAlert()
		alert.messageText = XULocalizedFormattedString("%@ couldn't connect to the Internet. The application will exit in one hour.", NSProcessInfo.processInfo().processName)
		alert.informativeText = XULocalizedFormattedString("%@ requires connection to the Internet to continue the trial properly.", NSProcessInfo.processInfo().processName)
		alert.addButtonWithTitle(XULocalizedString("OK"))
		alert.runModal()
		
		self._shortTrial()
	}
	
	@objc private func applicationDidFinishLaunching(aNotif: NSNotification) {
		if self.isFirstRun {
			self._showFirstRunAlert()
		}else if self.secondsLeft <= 0 {
			self._trialExpired()
		}
	}
	
	deinit {
		NSNotificationCenter.defaultCenter().removeObserver(self)
	}
	
	public required init(purchaseURL: NSURL, supportURL: NSURL, andTrialSessionsURL trialSessionsURL: NSURL) {
		self.purchaseURL = purchaseURL
		self.supportURL = supportURL
		self.trialSessionsURL = trialSessionsURL
		
		super.init()
		
		// Do not allow FCTrial in apps using XUCore.
		if NSClassFromString("FCTrial") != nil {
			NSException(name: NSInternalInconsistencyException, reason: "Do not use FCTrial.", userInfo: nil).raise()
		}
		
		self._innerInit()
		
		if NSApp == nil {
			NSNotificationCenter.defaultCenter().addObserver(self, selector: "applicationDidFinishLaunching:", name: NSApplicationDidFinishLaunchingNotification, object: nil)
		}else{
			self.applicationDidFinishLaunching(NSNotification(name: NSApplicationDidFinishLaunchingNotification, object: NSApp))
		}
	}
	
	/// Returns true if current run is the first one.
	public var isFirstRun: Bool {
		return _wasFirstRun
	}
	
	/// Opens a purchase URL.
	public func purchase() {
		self._openPurchaseURL()
	}
	
	/// Returns how many seconds are left of the trial.
	public var secondsLeft: NSTimeInterval {
		return _secondsLeft
	}
	
}

/// Currently, all time-based functionality is already in XUTrial. None of my apps
/// currently require any other kind of trial, so refactoring is a low priority 
/// right now.
public class XUTimeBasedTrial: XUTrial {
	
}
