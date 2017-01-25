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
open class XUTrial {
	
	/// Returns the shared trial. Will be nil when trial is not enabled, or
	/// AppStoreBuild is active.
	public static let shared: XUTrial? = {
		let setup = XUAppSetup
		if setup.isAppStoreBuild {
			return nil
		}
		
		guard let className = setup.trialClassName else {
			return nil
		}
		
		guard let trialClass = NSClassFromString(className) as? XUTrial.Type else {
			return nil
		}
		
		guard let purchaseURL = setup.purchaseURL, let supportURL = setup.supportURL, let trialSessionsURL = setup.trialSessionsURL else {
			XUForceLog("****WARNING**** - trying to create XUTrial, but one of the required URLs is not defined.")
			return nil
		}
		
		return trialClass.init(purchaseURL: purchaseURL as URL, supportURL: supportURL as URL, andTrialSessionsURL: trialSessionsURL as URL)
	}()
	
	fileprivate var _wasFirstRun: Bool = false
	
	fileprivate let purchaseURL: URL
	fileprivate let supportURL: URL
	fileprivate let trialSessionsURL: URL
	
	/// Opens a purchase URL.
	fileprivate func _openPurchaseURL() {
		NSWorkspace.shared().open(self.purchaseURL)
	}
	
	/// Opens a support URL.
	fileprivate func _openSupportURL() {
		NSWorkspace.shared().open(self.supportURL)
	}
	
	/// Returns a unique identifier of this computer and user.
	fileprivate var _sessionIdentifier: String {
		let macAddress = XUHardwareInfo.shared.serialNumber.md5Digest
		let sessionIdentifier = macAddress + NSUserName().md5Digest
		return sessionIdentifier
	}
	
	/// Calls _trialExpiredWithTrialID with nil trialID. Necessary for
	/// notifications and timer firing.
	@objc fileprivate func _trialExpired() {
		self.trialExpired(withTrialID: self.trialID)
	}
	
	/// Warns the user that there is not internet connection. Under such
	/// circumstances, the app exits in an hour.
	@objc fileprivate func _warnAboutNoInternetConnection() {
		let alert = NSAlert()
		alert.messageText = XULocalizedFormattedString("%@ couldn't connect to the Internet. The application will exit in one hour.", ProcessInfo.processInfo.processName, inBundle: XUCoreFramework.bundle)
		alert.informativeText = XULocalizedFormattedString("%@ requires connection to the Internet to continue the trial properly.", ProcessInfo.processInfo.processName, inBundle: XUCoreFramework.bundle)
		alert.addButton(withTitle: XULocalizedString("OK", inBundle: XUCoreFramework.bundle))
		alert.runModal()
		
		self.startShortTrial()
	}
	
	/// Called when the application is done launching. Automatically handles
	/// first launch - so whenever you override it, call super as well.
	@objc open func applicationDidFinishLaunching(_ aNotif: Notification) {
		if self.isFirstRun {
			self.showFirstRunAlert()
		}
	}
	
	deinit {
		NotificationCenter.default.removeObserver(self)
	}
	
	public required init(purchaseURL: URL, supportURL: URL, andTrialSessionsURL trialSessionsURL: URL) {
		self.purchaseURL = purchaseURL
		self.supportURL = supportURL
		self.trialSessionsURL = trialSessionsURL
		
		self.innerInit()
		
		if NSApp == nil {
			NotificationCenter.default.addObserver(self, selector: #selector(NSApplicationDelegate.applicationDidFinishLaunching(_:)), name: NSNotification.Name.NSApplicationDidFinishLaunching, object: nil)
		}else{
			self.applicationDidFinishLaunching(Notification(name: NSNotification.Name.NSApplicationDidFinishLaunching, object: NSApp))
		}
	}
	
	/// Inner init. This is called after application did finish launching.
	/// Each subclass must override this and setup the trial. Use
	/// self.noInternetConnectionDetected() to let the trial notify the user
	/// that no internet connection is available.
	open func innerInit() {
		XUFatalError()
	}
	
	/// Returns true if current run is the first one.
	open var isFirstRun: Bool {
		return _wasFirstRun
	}
	
	/// Notifies the user that no Internet connection is available and starts the
	/// short trial (1 hour).
	open func noInternetConnectionDetected() {
		if NSApp == nil {
			/// Schedule it for later
			NotificationCenter.default.addObserver(self, selector: #selector(XUTrial._warnAboutNoInternetConnection), name: NSNotification.Name.NSApplicationDidFinishLaunching, object: nil)
		}else{
			self._warnAboutNoInternetConnection()
		}
	}
	
	/// Opens a purchase URL.
	open func purchase() {
		self._openPurchaseURL()
	}
	
	/// Shows an alert when isFirstRun is true. Must be overridden by subclasses.
	@objc open func showFirstRunAlert() {
		XUFatalError()
	}
	
	/// Displays an alert with custom message about the trial. The alert includes
	/// a button to open the purchase link.
	open func showTrialAlert(withMessage message: String) {
		let alert = NSAlert()
		alert.messageText = message
		alert.informativeText = XULocalizedFormattedString("Enjoy our software! If you have any questions or run into any bugs, feel free to ask us at our support page %@", self.supportURL.absoluteString, inBundle: XUCoreFramework.bundle)
		alert.addButton(withTitle: XULocalizedString("Continue", inBundle: XUCoreFramework.bundle))
		alert.addButton(withTitle: XULocalizedString("Purchase...", inBundle: XUCoreFramework.bundle))
		
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
	open func startShortTrial() {
		Timer.scheduledTimer(timeInterval: XUTimeInterval.hour, target: self, selector: #selector(XUTrial._trialExpired), userInfo: nil, repeats: false)
	}
	
	/// Each subclass must override this. The message returns should include
	/// information why the trial is over - e.g. You've been using MyApp for 15
	/// days now.
	open var trialExpirationMessage: String {
		XUFatalError()
	}
	
	/// You can optionally store the trial ID here.
	open var trialID: String? = nil
	
	/// Notifies the user that the trial has expired. Trial ID is included. Trial
	/// ID may be nil.
	open func trialExpired(withTrialID trialID: String?) {
		if ProcessInfo.processInfo.arguments.contains("--disable-trial") {
			return
		}
		
		XUForceLog("trial expired, session identifier \(self._sessionIdentifier)")
		
		let appName = ProcessInfo.processInfo.processName
		let alert = NSAlert()
		alert.messageText = self.trialExpirationMessage
		alert.informativeText = XULocalizedFormattedString("You will be taken to a page where you'll be able to buy a copy. If you're still not sure if %@ is right for you and have some questions, contact us.%@", appName, trialID != nil ? " (Trial ID: \(trialID!))" : "", inBundle: XUCoreFramework.bundle)
		alert.addButton(withTitle: XULocalizedString("Purchase...", inBundle: XUCoreFramework.bundle))
		alert.addButton(withTitle: XULocalizedString("I'm Still Not Sure", inBundle: XUCoreFramework.bundle))
		
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
open class XUTimeBasedTrial: XUTrial {
	
	/// Returns the shared trial casted to time-based trial. Note that this is
	/// implicitely unwrapped - use it only if you indeed use the trial!
	public static var sharedTimeBasedTrial: XUTimeBasedTrial! {
		return self.shared as? XUTimeBasedTrial
	}
	
	fileprivate var _secondsLeft: TimeInterval = 0
	
	/// Registers the app with the trial server.
	fileprivate func _registerWithTrialServer() -> Bool {
		let identifier = XUAppSetup.applicationIdentifier.encodingIllegalURLCharacters
		let url = URL(string: self.trialSessionsURL.absoluteString + "?key=\(self._sessionIdentifier)&app=\(identifier)")!
		let request = NSMutableURLRequest(url: url)
		request.httpMethod = "POST"
		
		var genericResponse: URLResponse?
		_ = try? NSURLConnection.sendSynchronousRequest(request as URLRequest, returning: &genericResponse)
		
		guard let response = genericResponse as? HTTPURLResponse else {
			return false
		}
		
		return response.statusCode >= 200 && response.statusCode < 300
	}
	
	@objc open override func applicationDidFinishLaunching(_ aNotif: Notification) {
		if self.secondsLeft <= 0 {
			self._trialExpired()
		}
		
		super.applicationDidFinishLaunching(aNotif)
	}
	
	open override func innerInit() {
		let trialURL = URL(string: self.trialSessionsURL.absoluteString + "?key=\(self._sessionIdentifier)")!
		
		guard let data = try? Data(contentsOf: trialURL) else {
			self.noInternetConnectionDetected()
			return
		}
		
		guard let apps = (try? JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions())) as? [[String : String]] else {
			self.noInternetConnectionDetected()
			return
		}
		
		let identifier = XUAppSetup.applicationIdentifier
		guard let appDict = apps.find(where: { $0["app_identifier"] == identifier }) else {
			if self._registerWithTrialServer() {
				_secondsLeft = TimeInterval(XUAppSetup.timeBasedTrialDays) * XUTimeInterval.day
				_wasFirstRun = true
				Timer.scheduledTimer(timeInterval: _secondsLeft, target: self, selector: #selector(XUTrial.showFirstRunAlert), userInfo: nil, repeats: false)
			}else{
				self.noInternetConnectionDetected()
			}
			return
		}
		
		guard let trialID = appDict["id"], var dateString = appDict["created_at"] else {
			NSException(name: NSExceptionName.internalInconsistencyException, reason: "The appDict doesn't contain trial ID or created_at.", userInfo: nil).raise()
			return
		}
		
		XULog(trialID)
		
		dateString = dateString.replacingOccurrences(of: "T", with: " ")
		dateString = dateString.replacingOccurrences(of: "+", with: " +")
		
		let formatter = DateFormatter()
		formatter.dateFormat = "yyyy-MM-dd HH:mm:SS xx"
		
		let date = formatter.date(from: dateString) ?? Date()
		let now = Date()
		let difference = now.timeIntervalSince(date)
		
		_secondsLeft = TimeInterval(XUAppSetup.timeBasedTrialDays) * XUTimeInterval.day - abs(difference)
		
		if _secondsLeft > 0.0 {
			Timer.scheduledTimer(timeInterval: _secondsLeft, target: self, selector: #selector(XUTrial._trialExpired), userInfo: nil, repeats: false)
		}else{
			XUForceLog("trial expired, session identifier \(self._sessionIdentifier), trial ID \(trialID)")
			self.trialExpired(withTrialID: trialID)
		}
	}
	
	/// Returns how many seconds are left of the trial.
	open var secondsLeft: TimeInterval {
		return _secondsLeft
	}
	
	open override func showFirstRunAlert() {
		let appName = ProcessInfo.processInfo.processName
		self.showTrialAlert(withMessage: XULocalizedFormattedString("Thanks for trying out %@! You may use it for %li days now without any limitations. After the trial period expires, you'll need to purchase a copy of %@.", appName, XUAppSetup.timeBasedTrialDays, appName, inBundle: XUCoreFramework.bundle))
	}
	
	open override func startShortTrial() {
		_secondsLeft = XUTimeInterval.day
		
		super.startShortTrial()
	}
	
	open override var trialExpirationMessage: String {
		let appName = ProcessInfo.processInfo.processName
		return XULocalizedFormattedString("Thanks for trying out %@! You've been using it %li days now. To continue using %@ you need to purchase a copy.", appName, XUAppSetup.timeBasedTrialDays, appName, inBundle: XUCoreFramework.bundle)
	}
	
}

public extension Notification.Name {
	
	/// Posted whenever items left in the trial is changed.
	public static let ItemBasedTrialNumberOfItemsLeftDidChange = Notification.Name(rawValue: "XUItemBasedTrialNumberOfItemsLeftDidChangeNotification")
	
}

/// Trial that is item-based. E.g. you allow creating just 5 documents.
open class XUItemBasedTrial: XUTrial {
	
	/// Returns the shared trial casted to item-based trial. Note that this is
	/// implicitely unwrapped - use it only if you indeed use the trial!
	public static var sharedItemBasedTrial: XUItemBasedTrial! {
		return self.shared as? XUItemBasedTrial
	}
	
	fileprivate var _itemsLeft: Int = 0
	
	/// Posts a XUItemBasedTrialNumberOfItemsLeftDidChangeNotification notification.
	fileprivate func _notifyAboutItemsLeftChanged() {
		NotificationCenter.default.post(name: .ItemBasedTrialNumberOfItemsLeftDidChange, object: self)
	}
	
	/// The original FCItemBasedTrial included the bundle version in the session
	/// identifier as well. I am not including this here. Use the resetTrial()
	/// manually instead.
	/// private override var _sessionIdentifier: String {}
	
	@objc open override func applicationDidFinishLaunching(_ aNotif: Notification) {
		if self.itemsLeft <= 0 {
			self._trialExpired()
		}
		
		super.applicationDidFinishLaunching(aNotif)
	}
	
	/// Decreases number of items left. Posts the notification. Always is performed
	/// on main thread.
	open func decreaseItemsLeft() {
		XU_PERFORM_BLOCK_ON_MAIN_THREAD { () -> Void in
			self._itemsLeft -= 1

			self.saveTrialInformation()
			self._notifyAboutItemsLeftChanged()

			if self._itemsLeft <= 0 {
				self._trialExpired()
			}
		}
	}
	
	open override func innerInit() {
		let task = Process()
		task.launchPath = "/usr/bin/xattr"
		task.arguments = [
			"-p",
			self._sessionIdentifier,
			("~/Library/Preferences/" as NSString).expandingTildeInPath
		]
		
		let p = Pipe()
		task.standardOutput = p
		task.standardError = Pipe()
		
		task.launch()
		task.waitUntilExit()
		
		if task.terminationStatus == 1 {
			self._wasFirstRun = true
			_itemsLeft = XUAppSetup.itemBasedTrialNumberOfItems
			self.saveTrialInformation()
		}else{
			let data = p.fileHandleForReading.availableData
			let string = String(data: data) ?? ""
			if string.isEmpty {
				self._wasFirstRun = true
				_itemsLeft = XUAppSetup.itemBasedTrialNumberOfItems
				self.saveTrialInformation()
			}else{
				_itemsLeft = string.integerValue
			}
		}
		
		if _itemsLeft > XUAppSetup.itemBasedTrialNumberOfItems {
			_itemsLeft = 0
		}
	}
	
	/// Returns how many items are left of the trial.
	open var itemsLeft: Int {
		return _itemsLeft
	}
	
	/// Returns how many items have been user during the trial.
	open var itemsUsed: Int {
		return XUAppSetup.itemBasedTrialNumberOfItems - _itemsLeft
	}
	
	/// Resets the trial.
	open func resetTrial() {
		_itemsLeft = XUAppSetup.itemBasedTrialNumberOfItems
		
		self.saveTrialInformation()
	}
	
	/// Saves trial information.
	open func saveTrialInformation() {
		let task = Process()
		task.launchPath = "/usr/bin/xattr"
		task.arguments = [
			"-w",
			self._sessionIdentifier,
			"\(self.itemsLeft)",
			("~/Library/Preferences/" as NSString).expandingTildeInPath
		]
		
		task.launch()
		task.waitUntilExit()
	}
	
	open override func showFirstRunAlert() {
		let appName = ProcessInfo.processInfo.processName
		let numberOfItems = XUAppSetup.itemBasedTrialNumberOfItems
		let itemsName = XUAppSetup.itemBasedTrialItemName
		
		self.showTrialAlert(withMessage: XULocalizedFormattedString("Thanks for trying out %@! You may use it for %i %@ now without any limitations. After the trial period expires, you'll need to purchase a copy of %@.", appName, numberOfItems, itemsName, appName, inBundle: XUCoreFramework.bundle))
	}
	
	open override func startShortTrial() {
		_itemsLeft = 3
		
		super.startShortTrial()
	}
	
	open override var trialExpirationMessage: String {
		let appName = ProcessInfo.processInfo.processName
		let numberOfItems = XUAppSetup.itemBasedTrialNumberOfItems
		let itemsName = XUAppSetup.itemBasedTrialItemName
		
		return XULocalizedFormattedString("Thanks for trying out %@! You've used it for %i %@ now. To continue using %@ you need to purchase a copy.", appName, numberOfItems, itemsName, appName, inBundle: XUCoreFramework.bundle)
	}
	
}

