//
//  XUExceptionReporter.swift
//  XUCore
//
//  Created by Charlie Monroe on 11/22/15.
//  Copyright © 2015 Charlie Monroe Software. All rights reserved.
//

import Cocoa

/// This class handles showing the exception dialog to the user and sending the
/// report. The report is sent to a URL defined in XUApplicationSetup.
///
/// The report sent to the URL is a JSON dictionary in HTTP body which contains
/// the following keys and values (all values are strings):
///
/// build - build number of the app
/// description - user's description of the exception
/// email - email of the user
/// exception - exception string. Contains name of the exception, reason and the
///				userInfo dictionary
/// name - name of the app
/// os_version - version of the OS. On 10.9, this is whatever NSProcessInfo.
///				operatingSystemVersionString returns, on OS X 10.10+, it is
///				operatingSystemVersion values combined using a dot.
/// stacktrace - stack trace string.
/// version - version of the app
class XUExceptionReporter: NSObject, NSWindowDelegate {
	
	/// Contains a list of reporters being currently displayed.
	private static var _reporters: [XUExceptionReporter] = [ ]
	
	/// Shows an alert with privacy information.
	class func showPrivacyInformation() {
		let alert = NSAlert()
		alert.messageText = XULocalizedString("We value your feedback and wouldn't dare to collect any unwanted information. Your email address will not be stored anywhere and will only be used to inform you when this issue might be fixed or when we need more information in order to fix this problem.")
		alert.informativeText = XULocalizedString("Only the following information will be sent:\n• The description you provide.\n• The exception information below.\n• Version of this application.\n• Version of your system (OS).\n• Model of your computer (no MAC address or similar information that could identify your computer).")
		alert.addButtonWithTitle(XULocalizedString("OK"))
		alert.runModal()
	}
	
	/// Shows a new reporter window with the exception.
	class func showReporterForException(exception: NSException, andStackTrace stackTrace: String) {
		if [ NSAccessibilityException, NSPortTimeoutException, NSObjectInaccessibleException ].any({ exception.name == $0 }) {
			// Exceptions that commonly arise in Apple's code
			return
		}
		
		XU_PERFORM_BLOCK_ON_MAIN_THREAD { () -> Void in
			let reporter = XUExceptionReporter(exception: exception, stackTrace: stackTrace)
			_reporters.append(reporter)
			
			reporter._reporterWindow.center()
			reporter._reporterWindow.makeKeyAndOrderFront(nil)
			
			NSApp.runModalForWindow(reporter._reporterWindow)
			exit(1)
		}
	}
	
	
	private let _exception: NSException
	private let _nib: NSNib
	private var _topLevelObjects: NSArray?
	
	@IBOutlet private var _reporterWindow: NSWindow!
	
	@IBOutlet private var _emailTextField: NSTextField!
	@IBOutlet private var _stackTraceTextView: NSTextView!
	@IBOutlet private var _userInputTextView: NSTextView!
	
	private func _reportFailedReportSend() {
		let alert = NSAlert()
		alert.messageText = XULocalizedString("Could not post your report.")
		alert.informativeText = XULocalizedString("Check your Internet connection and try again.")
		alert.addButtonWithTitle(XULocalizedString("OK"))
		alert.beginSheetModalForWindow(_reporterWindow, completionHandler: nil)
	}
	
	private init(exception: NSException, stackTrace: String) {
		_exception = exception
		_nib = NSNib(nibNamed: "ExceptionReporter", bundle: XUCoreBundle)!
		
		super.init()
		
		_nib.instantiateWithOwner(self, topLevelObjects: &_topLevelObjects)
		
		_reporterWindow.delegate = self
		_reporterWindow.localizeWindow()
		
		_stackTraceTextView.string = stackTrace
		_stackTraceTextView.font = NSFont.userFixedPitchFontOfSize(11.0)
	}
	
	
	@IBAction func sendReport(sender: AnyObject?) {
		let valid = _emailTextField.stringValue.validateEmailAddress()
		
		if valid == .PhonyFormat {
			let alert = NSAlert()
			alert.messageText = XULocalizedString("Heh, nice try. Please, enter a valid email address.")
			alert.informativeText = XULocalizedString("We may need to get in touch with you in order to fix this. We don't bite, we won't sell the email address to anyone nor use it in any other way. We promise.")
			alert.addButtonWithTitle(XULocalizedString("OK"))
			alert.beginSheetModalForWindow(_reporterWindow, completionHandler: nil)
			return
		}else if valid == .WrongFormat {
			let alert = NSAlert()
			alert.messageText = XULocalizedString("You need to enter a valid email address.")
			alert.informativeText = XULocalizedString("We may need to get in touch with you in order to fix this.")
			alert.addButtonWithTitle(XULocalizedString("OK"))
			alert.beginSheetModalForWindow(_reporterWindow, completionHandler: nil)
			return
		}
		
		let OSVersionString: String
		if #available(OSX 10.10, *) {
		    let OSVersion = NSProcessInfo.processInfo().operatingSystemVersion
			OSVersionString = "\(OSVersion.majorVersion).\(OSVersion.minorVersion).\(OSVersion.patchVersion)"
		} else {
		    // Fallback on earlier versions
			OSVersionString = NSProcessInfo.processInfo().operatingSystemVersionString
		}
		
		let reportDictionary = [
			"description": _userInputTextView.string ?? "",
			"exception": "Name: \(_exception.name)\nReason: \(_exception.reason)\nFurther info: \(_exception.userInfo)",
			"stacktrace": _stackTraceTextView.string ?? "",
			"version": XUApplicationSetup.sharedSetup.applicationVersionNumber,
			"build": XUApplicationSetup.sharedSetup.applicationBuildNumber,
			"name": NSProcessInfo.processInfo().processName,
			"os_version": OSVersionString,
			"email": _emailTextField.stringValue
		]
		
		/// The exception catcher doesn't even start without a valid URL. We assume
		/// that it's still valid. This class is internal, so there should be no
		/// calls to this from outside of XUCore.
		let URL = XUApplicationSetup.sharedSetup.exceptionHandlerReportURL!
		
		
		let request = NSMutableURLRequest(URL: URL, cachePolicy: .ReloadIgnoringCacheData, timeoutInterval: 20.0)
		request.addJSONContentToHeader()
		request.HTTPMethod = "POST"
		request.HTTPBody = try? NSJSONSerialization.dataWithJSONObject(reportDictionary, options: NSJSONWritingOptions())
		
		var genericResponse: NSURLResponse?
		let _ = try? NSURLConnection.sendSynchronousRequest(request, returningResponse: &genericResponse)
		guard let response = genericResponse as? NSHTTPURLResponse else {
			self._reportFailedReportSend()
			return
		}
		
		if response.statusCode >= 200 && response.statusCode < 300 {
			let alert = NSAlert()
			alert.messageText = XULocalizedString("Thank you for the report!")
			alert.informativeText = XULocalizedString("We'll fix it as soon as possible!")
			alert.addButtonWithTitle(XULocalizedString("OK"))
			alert.beginSheetModalForWindow(_reporterWindow, completionHandler: { (_) -> Void in
				self._reporterWindow.close()
			})
		}else{
			self._reportFailedReportSend()
		}
	}
	
	@IBAction func showPrivacyInformation(sender: AnyObject?) {
		XUExceptionReporter.showPrivacyInformation()
	}
	
	func windowWillClose(notification: NSNotification) {
		guard let index = XUExceptionReporter._reporters.indexOf(self) else {
			return
		}
		
		NSApp.stopModal()
		XUExceptionReporter._reporters.removeAtIndex(index)
	}

}

