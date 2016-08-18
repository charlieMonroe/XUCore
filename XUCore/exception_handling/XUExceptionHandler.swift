//
//  XUExceptionHandler.swift
//  XUCore
//
//  Created by Charlie Monroe on 11/22/15.
//  Copyright © 2015 Charlie Monroe Software. All rights reserved.
//

import Foundation
import ExceptionHandling

/// This class catches and handles all uncaught exceptions and displays a message
/// about the exception, allowing the user to send a report. See XUApplicationStateProvider
/// for information on how to extend the exception handler and reporter, providing
/// additional information about your app's state.
public final class XUExceptionHandler: NSObject {
	
	/// Contains the shared handler. You should not call this, unless the exception
	/// reporting is enabled.
	public static let sharedExceptionHandler = XUExceptionHandler()
	
	/// This is called automatically by _XUCoreLauncher and starts exception
	/// handling. If, however, no exception handler reporting URL is found in
	/// XUApplicationSetup, the handler does not start. See XUExceptionReporter
	/// for more information.
	public class func startExceptionHandler() {
		if XUAppSetup.exceptionHandlerReportURL == nil {
			return
		}
		
		// Force initialization.
		_ = XUExceptionHandler.sharedExceptionHandler
	}
	
	/// Registers the exception handler.
	@objc private func _registerExceptionHandler() {
		let handler = NSExceptionHandler.defaultExceptionHandler()
		handler.setDelegate(self)
		
		let mask = (NSHandleUncaughtExceptionMask | NSHandleUncaughtSystemExceptionMask | NSHandleUncaughtRuntimeErrorMask)
		handler.setExceptionHandlingMask(mask)
		handler.setExceptionHangingMask(0)
	}
	
	@objc public override func exceptionHandler(sender: NSExceptionHandler!, shouldHandleException exception: NSException!, mask aMask: Int) -> Bool {
		
		// This method can be called from any thread, under any circumstances,
		// which is why we just note down the exception and we periodically check
		// for it in _checkForException.
		
		var stackTraceString = ""
		
		if let provider = XUAppSetup.applicationStateProvider {
			let exceptionCatcher = XUExceptionCatcher()
			exceptionCatcher.performBlock({ 
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
			let stackTraceSymbols = stackTraceSymbolsString.componentsSeparatedByString("  ").map({ NSNumber(integer: $0.stringByDeletingPrefix("0x").hexValue) })
			stackTraceString += _XUBacktrace.backtraceStringForAddresses(stackTraceSymbols).joinWithSeparator("\n")
			stackTraceString += "\n\n"
		}
		
		stackTraceString += XUStacktraceString()
		
		XUExceptionReporter.showReporterForException(exception, andStackTrace: stackTraceString)
		return true
	}
	
	private override init() {
		super.init()
		
		// Do not allow FCExceptionCatcher in apps using XUCore.
		if NSClassFromString("FCExceptionCatcher") != nil {
			NSException(name: NSInternalInconsistencyException, reason: "Do not use FCExceptionCatcher.", userInfo: nil).raise()
		}
		
		// Since NSApplication installs its own handler, we need to make sure that
		// this is called *after* the app is finished launching. We can detect this
		// by checking NSApp for nil.
		if NSApp == nil {
			// App not yet fully launched, defer the handler registration.
			NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(XUExceptionHandler._registerExceptionHandler), name: NSApplicationDidFinishLaunchingNotification, object: nil)
		}else{
			// The app is fully launched.
			self._registerExceptionHandler()
		}
	}
	
}