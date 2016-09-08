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
	fileprivate static var _reporters: [XUExceptionReporter] = [ ]
	
	/// Shows an alert with privacy information.
	class func showPrivacyInformation() {
		let alert = NSAlert()
		alert.messageText = XULocalizedString("We value your feedback and wouldn't dare to collect any unwanted information. Your email address will not be stored anywhere and will only be used to inform you when this issue might be fixed or when we need more information in order to fix this problem.", inBundle: XUCoreBundle)
		alert.informativeText = XULocalizedString("Only the following information will be sent:\n• The description you provide.\n• The exception information below.\n• Version of this application.\n• Version of your system (OS).\n• Model of your computer (no MAC address or similar information that could identify your computer).", inBundle: XUCoreBundle)
		alert.addButton(withTitle: XULocalizedString("OK", inBundle: XUCoreBundle))
		alert.runModal()
	}
	
	/// Shows a new reporter window with the exception.
	class func showReporterForException(_ exception: NSException, andStackTrace stackTrace: String) {
		if [ NSExceptionName.accessibilityException, NSExceptionName.portTimeoutException, NSExceptionName.objectInaccessibleException ].contains(where: { exception.name == $0 }) {
			// Exceptions that commonly arise in Apple's code
			return
		}
		
		XU_PERFORM_BLOCK_ON_MAIN_THREAD { () -> Void in
			let reporter = XUExceptionReporter(exception: exception, stackTrace: stackTrace)
			_reporters.append(reporter)
			
			reporter._reporterWindow.center()
			reporter._reporterWindow.makeKeyAndOrderFront(nil)
			
			NSApp.runModal(for: reporter._reporterWindow)
			exit(1)
		}
	}
	
	
	fileprivate let _exception: NSException
	fileprivate let _nib: NSNib
	fileprivate var _topLevelObjects: NSArray?
	
	@IBOutlet fileprivate var _reporterWindow: NSWindow!
	
	@IBOutlet fileprivate weak var _emailTextField: NSTextField!
	@IBOutlet fileprivate var _stackTraceTextView: NSTextView!
	@IBOutlet fileprivate var _userInputTextView: NSTextView!
	
	fileprivate func _reportFailedReportSend() {
		let alert = NSAlert()
		alert.messageText = XULocalizedString("Could not post your report.", inBundle: XUCoreBundle)
		alert.informativeText = XULocalizedString("Check your Internet connection and try again.", inBundle: XUCoreBundle)
		alert.addButton(withTitle: XULocalizedString("OK", inBundle: XUCoreBundle))
		alert.beginSheetModal(for: _reporterWindow, completionHandler: nil)
	}
	
	fileprivate init(exception: NSException, stackTrace: String) {
		_exception = exception
		_nib = NSNib(nibNamed: "ExceptionReporter", bundle: XUCoreBundle)!
		
		super.init()
		
		_nib.instantiate(withOwner: self, topLevelObjects: &_topLevelObjects!)
		
		_reporterWindow.delegate = self
		_reporterWindow.localizeWindow(XUCoreBundle)
		
		_stackTraceTextView.string = stackTrace
		_stackTraceTextView.font = NSFont.userFixedPitchFont(ofSize: 11.0)
	}
	
	
	@IBAction func sendReport(_ sender: AnyObject?) {
		let valid = _emailTextField.stringValue.validateEmailAddress()
		
		if valid == .phony {
			let alert = NSAlert()
			alert.messageText = XULocalizedString("Heh, nice try. Please, enter a valid email address.", inBundle: XUCoreBundle)
			alert.informativeText = XULocalizedString("We may need to get in touch with you in order to fix this. We don't bite, we won't sell the email address to anyone nor use it in any other way. We promise.", inBundle: XUCoreBundle)
			alert.addButton(withTitle: XULocalizedString("OK", inBundle: XUCoreBundle))
			alert.beginSheetModal(for: _reporterWindow, completionHandler: nil)
			return
		}else if valid == .wrong {
			let alert = NSAlert()
			alert.messageText = XULocalizedString("You need to enter a valid email address.", inBundle: XUCoreBundle)
			alert.informativeText = XULocalizedString("We may need to get in touch with you in order to fix this.", inBundle: XUCoreBundle)
			alert.addButton(withTitle: XULocalizedString("OK", inBundle: XUCoreBundle))
			alert.beginSheetModal(for: _reporterWindow, completionHandler: nil)
			return
		}
		
		if _userInputTextView.string == nil || _userInputTextView.string!.isEmpty {
			let alert = NSAlert()
			alert.messageText = XULocalizedString("Please, provide some details as to when this exception happened.", inBundle: XUCoreBundle)
			alert.informativeText = XULocalizedString("Include information about ongoing tasks in the application, if the application was in the foreground, or background; if you have clicked on anything, etc. Trying to figure out the bug just from the report can be hard and without additional information impossible.", inBundle: XUCoreBundle)
			alert.addButton(withTitle: XULocalizedString("OK", inBundle: XUCoreBundle))
			alert.beginSheetModal(for: _reporterWindow, completionHandler: nil)
			
			_reporterWindow.makeFirstResponder(_userInputTextView)
			return
		}
		
		if _userInputTextView.string!.characters.contains(where: { !$0.isASCIIOrPunctuation }) {
			let alert = NSAlert()
			alert.messageText = XULocalizedFormattedString("Your message contains special characters which usually indicates that the message is not written in English. Please note that while %@ is translated into various languages, support is provided in English only. Thank you for understanding.", ProcessInfo.processInfo.processName, inBundle: XUCoreBundle)
			alert.informativeText = XULocalizedString("You can send the report anyway, but if the message indeed isn't in English, I won't be able to provide you with full support.", inBundle: XUCoreBundle)
			alert.addButton(withTitle: "Cancel")
			alert.addButton(withTitle: "Send Anyway")
			if alert.runModal() == NSAlertFirstButtonReturn {
				return
			}
		}
		
		
		let OSVersion = ProcessInfo.processInfo.operatingSystemVersion
		let OSVersionString = "\(OSVersion.majorVersion).\(OSVersion.minorVersion).\(OSVersion.patchVersion)"
		
		let reportDictionary = [
			"description": _userInputTextView.string ?? "",
			"exception": "Name: \(_exception.name)\nReason: \(_exception.reason ?? "")\nFurther info: \(_exception.userInfo ?? [:])",
			"stacktrace": _stackTraceTextView.string ?? "",
			"version": XUAppSetup.applicationVersionNumber,
			"build": XUAppSetup.applicationBuildNumber,
			"name": ProcessInfo.processInfo.processName,
			"os_version": OSVersionString,
			"email": _emailTextField.stringValue
		]
		
		/// The exception catcher doesn't even start without a valid URL. We assume
		/// that it's still valid. This class is internal, so there should be no
		/// calls to this from outside of XUCore.
		let url = XUAppSetup.exceptionHandlerReportURL!
		
		
		let request = NSMutableURLRequest(url: url, cachePolicy: .reloadIgnoringCacheData, timeoutInterval: 20.0)
		request.addJSONContentToHeader()
		request.httpMethod = "POST"
		request.httpBody = try? JSONSerialization.data(withJSONObject: reportDictionary, options: JSONSerialization.WritingOptions())
		
		var genericResponse: URLResponse?
		let _ = try? NSURLConnection.sendSynchronousRequest(request as URLRequest, returning: &genericResponse)
		guard let response = genericResponse as? HTTPURLResponse else {
			self._reportFailedReportSend()
			return
		}
		
		if response.statusCode >= 200 && response.statusCode < 300 {
			let alert = NSAlert()
			alert.messageText = XULocalizedString("Thank you for the report!", inBundle: XUCoreBundle)
			alert.informativeText = XULocalizedString("We'll fix it as soon as possible!", inBundle: XUCoreBundle)
			alert.addButton(withTitle: XULocalizedString("OK", inBundle: XUCoreBundle))
			alert.beginSheetModal(for: _reporterWindow, completionHandler: { (_) -> Void in
				self._reporterWindow.close()
			})
		}else{
			self._reportFailedReportSend()
		}
	}
	
	@IBAction func showPrivacyInformation(_ sender: AnyObject?) {
		XUExceptionReporter.showPrivacyInformation()
	}
	
	func windowWillClose(_ notification: Notification) {
		guard let index = XUExceptionReporter._reporters.index(of: self) else {
			return
		}
		
		NSApp.stopModal()
		XUExceptionReporter._reporters.remove(at: index)
	}

}

