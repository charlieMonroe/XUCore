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
/// - trialSessionsURL - see subclasses about what the URL must be capabled
///						of handling.
///
public class XUTrial: NSObject {
	
	/// Returns the shared trial. Will be nil when trial is not enabled, or
	/// AppStoreBuild is active.
	public static let sharedTrial: XUTrial? = {
		let setup = XUApplicationSetup.sharedSetup
		if setup.isAppStoreBuild {
			return nil
		}
		
		guard let className = setup.trialClassName else {
			return nil
		}
		
		guard let trialClass = NSClassFromString(className) as? XUTrial.Type else {
			return nil
		}
		
		guard let purchaseURL = setup.purchaseURL, supportURL = setup.supportURL, trialSessionsURL = setup.trialSessionsURL else {
			XUForceLog("****WARNING**** - trying to create XUTrial, but one of the required URLs is not defined.")
			return nil
		}
		
		if NSClassFromString("FCTrial") != nil {
			NSException(name: NSInternalInconsistencyException, reason: "Do not use FCTrial in combination with XUCore.", userInfo: nil).raise()
			return nil
		}
		
		return trialClass.init(purchaseURL: purchaseURL, supportURL: supportURL, andTrialSessionsURL: trialSessionsURL)
	}()
	
	private var _wasFirstRun: Bool = false
	
	private let purchaseURL: NSURL
	private let supportURL: NSURL
	private let trialSessionsURL: NSURL
	
	/// Opens a purchase URL.
	private func _openPurchaseURL() {
		NSWorkspace.sharedWorkspace().openURL(self.purchaseURL)
	}
	
	/// Opens a support URL.
	private func _openSupportURL() {
		NSWorkspace.sharedWorkspace().openURL(self.supportURL)
	}
	
	/// Returns a unique identifier of this computer and user.
	private var _sessionIdentifier: String {
		let macAddress = XUHardwareInfo.sharedHardwareInfo.serialNumber.MD5Digest
		let sessionIdentifier = macAddress + NSUserName().MD5Digest
		return sessionIdentifier
	}
	
	/// Calls _trialExpiredWithTrialID with nil trialID. Necessary for
	/// notifications and timer firing.
	@objc private func _trialExpired() {
		self.trialExpiredWithTrialID(self.trialID)
	}
	
	/// Warns the user that there is not internet connection. Under such
	/// circumstances, the app exits in an hour.
	@objc private func _warnAboutNoInternetConnection() {
		let alert = NSAlert()
		alert.messageText = XULocalizedFormattedString("%@ couldn't connect to the Internet. The application will exit in one hour.", NSProcessInfo.processInfo().processName, inBundle: XUCoreBundle)
		alert.informativeText = XULocalizedFormattedString("%@ requires connection to the Internet to continue the trial properly.", NSProcessInfo.processInfo().processName, inBundle: XUCoreBundle)
		alert.addButtonWithTitle(XULocalizedString("OK", inBundle: XUCoreBundle))
		alert.runModal()
		
		self.startShortTrial()
	}
	
	/// Called when the application is done launching. Automatically handles
	/// first launch - so whenever you override it, call super as well.
	@objc public func applicationDidFinishLaunching(aNotif: NSNotification) {
		if self.isFirstRun {
			self.showFirstRunAlert()
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
		
		self.innerInit()
		
		if NSApp == nil {
			NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(NSApplicationDelegate.applicationDidFinishLaunching(_:)), name: NSApplicationDidFinishLaunchingNotification, object: nil)
		}else{
			self.applicationDidFinishLaunching(NSNotification(name: NSApplicationDidFinishLaunchingNotification, object: NSApp))
		}
	}
	
	/// Inner init. This is called after application did finish launching.
	/// Each subclass must override this and setup the trial. Use
	/// self.noInternetConnectionDetected() to let the trial notify the user
	/// that no internet connection is available.
	public func innerInit() {
		XUThrowAbstractException()
	}
	
	/// Returns true if current run is the first one.
	public var isFirstRun: Bool {
		return _wasFirstRun
	}
	
	/// Notifies the user that no Internet connection is available and starts the
	/// short trial (1 hour).
	public func noInternetConnectionDetected() {
		if NSApp == nil {
			/// Schedule it for later
			NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(XUTrial._warnAboutNoInternetConnection), name: NSApplicationDidFinishLaunchingNotification, object: nil)
		}else{
			self._warnAboutNoInternetConnection()
		}
	}
	
	/// Opens a purchase URL.
	public func purchase() {
		self._openPurchaseURL()
	}
	
	/// Shows an alert when isFirstRun is true. Must be overridden by subclasses.
	@objc public func showFirstRunAlert() {
		XUThrowAbstractException()
	}
	
	/// Displays an alert with custom message about the trial. The alert includes
	/// a button to open the purchase link.
	public func showTrialAlertWithMessage(message: String) {
		let alert = NSAlert()
		alert.messageText = message
		alert.informativeText = XULocalizedFormattedString("Enjoy our software! If you have any questions or run into any bugs, feel free to ask us at our support page %@", self.supportURL.absoluteString, inBundle: XUCoreBundle)
		alert.addButtonWithTitle(XULocalizedString("Continue", inBundle: XUCoreBundle))
		alert.addButtonWithTitle(XULocalizedString("Purchase...", inBundle: XUCoreBundle))
		
		let alertResult = alert.runModal()
		if alertResult == NSAlertFirstButtonReturn {
			// Continue
			return
		}else if alertResult == NSAlertSecondButtonReturn {
			// Purchase
			self._openPurchaseURL()
		}
	}
	
	/// This method is called when the trial is unable to connect to the trial
	/// server and hence only one-hour trial is provided. By default, schedules
	/// a timer that is fired after 1 hour and calls trialExpiredWithTrialID(nil).
	public func startShortTrial() {
		NSTimer.scheduledTimerWithTimeInterval(3600.0, target: self, selector: #selector(XUTrial._trialExpired), userInfo: nil, repeats: false)
	}
	
	/// Each subclass must override this. The message returns should include
	/// information why the trial is over - e.g. You've been using MyApp for 15
	/// days now.
	public var trialExpirationMessage: String {
		XUThrowAbstractException()
	}
	
	/// You can optionally store the trial ID here.
	public var trialID: String? = nil
	
	/// Notifies the user that the trial has expired. Trial ID is included. Trial
	/// ID may be nil.
	public func trialExpiredWithTrialID(trialID: String?) {
		if NSProcessInfo.processInfo().arguments.contains("--disable-trial") {
			return
		}
		
		XUForceLog("trial expired, session identifier \(self._sessionIdentifier)")
		
		let appName = NSProcessInfo.processInfo().processName
		let alert = NSAlert()
		alert.messageText = self.trialExpirationMessage
		alert.informativeText = XULocalizedFormattedString("You will be taken to a page where you'll be able to buy a copy. If you're still not sure if %@ is right for you and have some questions, contact us.%@", appName, trialID != nil ? " (Trial ID: \(trialID!))" : "", inBundle: XUCoreBundle)
		alert.addButtonWithTitle(XULocalizedString("Purchase...", inBundle: XUCoreBundle))
		alert.addButtonWithTitle(XULocalizedString("I'm Still Not Sure", inBundle: XUCoreBundle))
		
		let result = alert.runModal()
		if result == NSAlertFirstButtonReturn {
			self._openPurchaseURL()
		}else if result == NSAlertSecondButtonReturn {
			self._openSupportURL()
		}
		
		exit(0)
	}
	
}

/// Trial that is time-based. See XUTrial for generic information. Aside from
/// that, the session URL must be capable of the following:
///
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
public class XUTimeBasedTrial: XUTrial {
	
	/// Returns the shared trial casted to time-based trial. Note that this is
	/// implicitely unwrapped - use it only if you indeed use the trial!
	public static var sharedTimeBasedTrial: XUTimeBasedTrial! {
		return self.sharedTrial as? XUTimeBasedTrial
	}
	
	private var _secondsLeft: NSTimeInterval = 0
	
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
	
	@objc public override func applicationDidFinishLaunching(aNotif: NSNotification) {
		if self.secondsLeft <= 0 {
			self._trialExpired()
		}
		
		super.applicationDidFinishLaunching(aNotif)
	}
	
	public override func innerInit() {
		let trialURL = NSURL(string: self.trialSessionsURL.absoluteString + "?key=\(self._sessionIdentifier)")!
		
		guard let data = NSData(contentsOfURL: trialURL) else {
			self.noInternetConnectionDetected()
			return
		}
		
		guard let apps = (try? NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions())) as? [[String : String]] else {
			self.noInternetConnectionDetected()
			return
		}
		
		let identifier = XUApplicationSetup.sharedSetup.applicationIdentifier
		guard let appDict = apps.find({ $0["app_identifier"] == identifier }) else {
			if self._registerWithTrialServer() {
				_secondsLeft = NSTimeInterval(XUApplicationSetup.sharedSetup.timeBasedTrialDays) * (24.0 * 3600.0)
				_wasFirstRun = true
				NSTimer.scheduledTimerWithTimeInterval(_secondsLeft, target: self, selector: #selector(XUTrial.showFirstRunAlert), userInfo: nil, repeats: false)
			}else{
				self.noInternetConnectionDetected()
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
		
		let formatter = NSDateFormatter()
		formatter.dateFormat = "yyyy-MM-dd HH:mm:SS xx"
		
		let date = formatter.dateFromString(dateString) ?? NSDate()
		let now = NSDate()
		let difference = now.timeIntervalSinceDate(date)
		
		_secondsLeft = NSTimeInterval(XUApplicationSetup.sharedSetup.timeBasedTrialDays) * (24.0 * 3600.0) - abs(difference)
		
		if _secondsLeft > 0.0 {
			NSTimer.scheduledTimerWithTimeInterval(_secondsLeft, target: self, selector: #selector(XUTrial._trialExpired), userInfo: nil, repeats: false)
		}else{
			XUForceLog("trial expired, session identifier \(self._sessionIdentifier), trial ID \(trialID)")
			self.trialExpiredWithTrialID(trialID)
		}
	}
	
	/// Returns how many seconds are left of the trial.
	public var secondsLeft: NSTimeInterval {
		return _secondsLeft
	}
	
	public override func showFirstRunAlert() {
		let appName = NSProcessInfo.processInfo().processName
		self.showTrialAlertWithMessage(XULocalizedFormattedString("Thanks for trying out %@! You may use it for %li days now without any limitations. After the trial period expires, you'll need to purchase a copy of %@.", appName, XUApplicationSetup.sharedSetup.timeBasedTrialDays, appName, inBundle: XUCoreBundle))
	}
	
	public override func startShortTrial() {
		_secondsLeft = 3600.0
		
		super.startShortTrial()
	}
	
	public override var trialExpirationMessage: String {
		let appName = NSProcessInfo.processInfo().processName
		return XULocalizedFormattedString("Thanks for trying out %@! You've been using it %li days now. To continue using %@ you need to purchase a copy.", appName, XUApplicationSetup.sharedSetup.timeBasedTrialDays, appName, inBundle: XUCoreBundle)
	}
	
}

/// Posted whenever items left in the trial is changed.
public let XUItemBasedTrialNumberOfItemsLeftDidChangeNotification = "XUItemBasedTrialNumberOfItemsLeftDidChangeNotification"

/// Trial that is item-based. E.g. you allow creating just 5 documents.
public class XUItemBasedTrial: XUTrial {
	
	/// Returns the shared trial casted to item-based trial. Note that this is
	/// implicitely unwrapped - use it only if you indeed use the trial!
	public static var sharedItemBasedTrial: XUItemBasedTrial! {
		return self.sharedTrial as? XUItemBasedTrial
	}
	
	/// This is a convenience method that returns the notification name. Use it
	/// from ObjC only.
	public static var itemBasedTrialNumberOfItemsLeftDidChangeNotification: String {
		return XUItemBasedTrialNumberOfItemsLeftDidChangeNotification
	}
	
	private var _itemsLeft: Int = 0
	
	/// Posts a XUItemBasedTrialNumberOfItemsLeftDidChangeNotification notification.
	private func _notifyAboutItemsLeftChanged() {
		NSNotificationCenter.defaultCenter().postNotificationName(XUItemBasedTrialNumberOfItemsLeftDidChangeNotification, object: self)
	}
	
	/// The original FCItemBasedTrial included the bundle version in the session
	/// identifier as well. I am not including this here. Use the resetTrial()
	/// manually instead.
	/// private override var _sessionIdentifier: String {}
	
	@objc public override func applicationDidFinishLaunching(aNotif: NSNotification) {
		if self.itemsLeft <= 0 {
			self._trialExpired()
		}
		
		super.applicationDidFinishLaunching(aNotif)
	}
	
	/// Decreases number of items left. Posts the notification. Always is performed
	/// on main thread.
	public func decreaseItemsLeft() {
		XU_PERFORM_BLOCK_ON_MAIN_THREAD { () -> Void in
			self._itemsLeft -= 1

			self.saveTrialInformation()
			self._notifyAboutItemsLeftChanged()

			if self._itemsLeft <= 0 {
				self._trialExpired()
			}
		}
	}
	
	public override func innerInit() {
		let task = NSTask()
		task.launchPath = "/usr/bin/xattr"
		task.arguments = [
			"-p",
			self._sessionIdentifier,
			("~/Library/Preferences/" as NSString).stringByExpandingTildeInPath
		]
		
		let p = NSPipe()
		task.standardOutput = p
		task.standardError = NSPipe()
		
		task.launch()
		task.waitUntilExit()
		
		if task.terminationStatus == 1 {
			self._wasFirstRun = true
			_itemsLeft = XUApplicationSetup.sharedSetup.itemBasedTrialNumberOfItems
			self.saveTrialInformation()
		}else{
			let data = p.fileHandleForReading.availableData
			let string = String(data: data) ?? ""
			if string.isEmpty {
				self._wasFirstRun = true
				_itemsLeft = XUApplicationSetup.sharedSetup.itemBasedTrialNumberOfItems
				self.saveTrialInformation()
			}else{
				_itemsLeft = string.integerValue
			}
		}
		
		if _itemsLeft > XUApplicationSetup.sharedSetup.itemBasedTrialNumberOfItems {
			self._trialExpired()
			return
		}
	}
	
	/// Returns how many items are left of the trial.
	public var itemsLeft: Int {
		return _itemsLeft
	}
	
	/// Returns how many items have been user during the trial.
	public var itemsUsed: Int {
		return XUApplicationSetup.sharedSetup.itemBasedTrialNumberOfItems - _itemsLeft
	}
	
	/// Resets the trial.
	public func resetTrial() {
		_itemsLeft = XUApplicationSetup.sharedSetup.itemBasedTrialNumberOfItems
		
		self.saveTrialInformation()
	}
	
	/// Saves trial information.
	public func saveTrialInformation() {
		let task = NSTask()
		task.launchPath = "/usr/bin/xattr"
		task.arguments = [
			"-w",
			self._sessionIdentifier,
			"\(self.itemsLeft)",
			("~/Library/Preferences/" as NSString).stringByExpandingTildeInPath
		]
		
		task.launch()
		task.waitUntilExit()
	}
	
	public override func showFirstRunAlert() {
		let appName = NSProcessInfo.processInfo().processName
		let numberOfItems = XUApplicationSetup.sharedSetup.itemBasedTrialNumberOfItems
		let itemsName = XUApplicationSetup.sharedSetup.itemBasedTrialItemName
		
		self.showTrialAlertWithMessage(XULocalizedFormattedString("Thanks for trying out %@! You may use it for %i %@ now without any limitations. After the trial period expires, you'll need to purchase a copy of %@.", appName, numberOfItems, itemsName, appName, inBundle: XUCoreBundle))
	}
	
	public override func startShortTrial() {
		_itemsLeft = 3
		
		super.startShortTrial()
	}
	
	public override var trialExpirationMessage: String {
		let appName = NSProcessInfo.processInfo().processName
		let numberOfItems = XUApplicationSetup.sharedSetup.itemBasedTrialNumberOfItems
		let itemsName = XUApplicationSetup.sharedSetup.itemBasedTrialItemName
		
		return XULocalizedFormattedString("Thanks for trying out %@! You've used it for %i %@ now. To continue using %@ you need to purchase a copy.", appName, numberOfItems, itemsName, appName, inBundle: XUCoreBundle)
	}
	
}

