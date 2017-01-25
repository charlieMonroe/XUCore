//
//  XUExceptionHandler.swift
//  XUCore
//
//  Created by Charlie Monroe on 11/22/15.
//  Copyright © 2015 Charlie Monroe Software. All rights reserved.
//

import Foundation
import ExceptionHandling

private extension XUPreferences.Key {
	static let ApplicationIsPendingLaunch: XUPreferences.Key = XUPreferences.Key(rawValue: "XUExceptionReporter.ApplicationIsPendingLaunch")
	static let LastLaunchDidCrash: XUPreferences.Key = XUPreferences.Key(rawValue: "XUExceptionReporter.LastLaunchDidCrash")
	static let NumberOfConsecutiveCrashes: XUPreferences.Key = XUPreferences.Key(rawValue: "XUExceptionReporter.NumberOfConsecutiveCrashes")
}

/// Extension to XUPreferences which allows you to track how often does your app
/// crash and if it did crash previously. This information can be used for resetting
/// some values within the app that are causing the crash.
///
/// Note that you need to have XUExceptionReporter registered and to have
/// XUPreferences enabled - (XUPreferences.isApplicationUsingPreferences).
public extension XUPreferences {
	
	/// Is marked as true during initialization of XUExceptionReporter (which
	/// usually occurrs before NSApplicationMain is called) and is marked as false
	/// once the application finishes launching. This way we can detect crashes
	/// before the application is done launching.
	fileprivate var applicationIsPendingLaunch: Bool {
		get {
			return self.boolean(for: .ApplicationIsPendingLaunch)
		}
		set {
			self.set(boolean: newValue, forKey: .ApplicationIsPendingLaunch)
		}
	}
	
	/// Indicates whether the previous launch did crash or not.
	public internal(set) var lastLaunchDidCrash: Bool {
		get {
			return self.boolean(for: .LastLaunchDidCrash)
		}
		set {
			self.set(boolean: newValue, forKey: .LastLaunchDidCrash)
		}
	}
	
	/// Returns number of consecutive crashes.
	public internal(set) var numberOfConsecutiveCrashes: Int {
		get {
			return self.integer(for: .NumberOfConsecutiveCrashes)
		}
		set {
			self.set(integer: newValue, forKey: .NumberOfConsecutiveCrashes)
		}
	}
	
}


/// This class catches and handles all uncaught exceptions and displays a message
/// about the exception, allowing the user to send a report. See XUApplicationStateProvider
/// for information on how to extend the exception handler and reporter, providing
/// additional information about your app's state.
public final class XUExceptionHandler: NSObject {
	
	/// Contains the shared handler. You should not call this, unless the exception
	/// reporting is enabled.
	public static let shared = XUExceptionHandler()
	
	/// This is called automatically by _XUCoreLauncher and starts exception
	/// handling. If, however, no exception handler reporting URL is found in
	/// XUApplicationSetup, the handler does not start. See XUExceptionReporter
	/// for more information.
	public class func startExceptionHandler() {
		if XUAppSetup.exceptionHandlerReportURL == nil {
			return
		}
		
		// Force initialization.
		_ = XUExceptionHandler.shared
	}
	
	@objc private func _applicationDidFinishLaunching() {
		XUPreferences.shared.perform(andSynchronize: { (prefs) in
			prefs.applicationIsPendingLaunch = false
		})
	}
	
	@objc private func _applicationWillTerminate() {
		if XUPreferences.isApplicationUsingPreferences {
			XUPreferences.shared.perform(andSynchronize: { (prefs) in
				prefs.lastLaunchDidCrash = false
				prefs.numberOfConsecutiveCrashes = 0
			})
		}
	}
	
	/// Registers the exception handler.
	@objc fileprivate func _registerExceptionHandler() {
		let handler = NSExceptionHandler.default()
		handler?.setDelegate(self)
		
		let mask = (NSHandleUncaughtExceptionMask | NSHandleUncaughtSystemExceptionMask | NSHandleUncaughtRuntimeErrorMask)
		handler?.setExceptionHandlingMask(mask)
		handler?.setExceptionHangingMask(0)
	}
	
	@objc public override func exceptionHandler(_ sender: NSExceptionHandler!, shouldHandle exception: NSException!, mask aMask: Int) -> Bool {
		
		// This method can be called from any thread, under any circumstances,
		// which is why we just note down the exception and we periodically check
		// for it in _checkForException.
		
		var stackTraceString = ""
		
		if let provider = XUAppSetup.applicationStateProvider {
			let exceptionCatcher = XUExceptionCatcher()
			exceptionCatcher.perform({ 
				stackTraceString += provider.provideApplicationState() + "\n\n"
			}, withCatchHandler: { (exception) in
				stackTraceString += "Failed to get application state - fetching it resulted in an exception \(exception).\n\n"
			}, andFinallyBlock: {})
		}
		
		stackTraceString += exception.description + "\n\n"
		
		let exceptionStackTrace = XUStacktraceStringFromException(exception)
		if !exceptionStackTrace.isEmpty {
			stackTraceString = exceptionStackTrace + "\n\n"
		}
		
		if let stackTraceSymbolsString = exception.userInfo?[NSStackTraceKey] as? String {
			let stackTraceSymbols = stackTraceSymbolsString.components(separatedBy: "  ").map({ NSNumber(value: $0.deleting(prefix: "0x").hexValue as Int) })
			stackTraceString += _XUBacktrace.backtraceString(forAddresses: stackTraceSymbols).joined(separator: "\n")
			stackTraceString += "\n\n"
		}
		
		stackTraceString += XUStacktraceString()
		
		XUExceptionReporter.showReporter(for: exception, thread: Thread.current, queue: OperationQueue.current, andStackTrace: stackTraceString)
		return true
	}
	
	fileprivate override init() {
		super.init()
		
		// Since NSApplication installs its own handler, we need to make sure that
		// this is called *after* the app is finished launching. We can detect this
		// by checking NSApp for nil.
		if NSApp == nil {
			// App not yet fully launched, defer the handler registration.
			NotificationCenter.default.addObserver(self, selector: #selector(XUExceptionHandler._registerExceptionHandler), name: NSNotification.Name.NSApplicationDidFinishLaunching, object: nil)
		} else {
			// The app is fully launched.
			self._registerExceptionHandler()
		}
		
		/// We observe regular application termination for resetting XUPreferences.lastLaunchDidCrash.
		NotificationCenter.default.addObserver(self, selector: #selector(_applicationWillTerminate), name: .NSApplicationWillTerminate, object: nil)
		
		/// And we observe that the application did finish launching to detect
		/// crashes between the process being launched.
		NotificationCenter.default.addObserver(self, selector: #selector(_applicationDidFinishLaunching), name: .NSApplicationDidFinishLaunching, object: nil)
		
		if NSApp == nil {
			XUPreferences.shared.perform(andSynchronize: { (prefs) in
				if prefs.applicationIsPendingLaunch {
					// We've already crashed last time
					prefs.lastLaunchDidCrash = true
					prefs.numberOfConsecutiveCrashes += 1
				}
				
				prefs.applicationIsPendingLaunch = true
			})
		}

	}
	
}
