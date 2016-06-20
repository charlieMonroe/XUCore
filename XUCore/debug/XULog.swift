//
//  XULog.swift
//  DownieCore
//
//  Created by Charlie Monroe on 10/28/15.
//  Copyright © 2015 Charlie Monroe Software. All rights reserved.
//

import Foundation

#if os(OSX)
	import Cocoa
#endif

public let XULoggingStatusChangedNotification = "XULoggingStatusChangedNotification"

/// We are not exposing this defaults key. Please, use XULoggingEnabled() function
/// and XUSetLoggingEnabled().
private let XULoggingEnabledDefaultsKey: String = "XULoggingEnabled"

private var _cachedPreferences = false
private var _didCachePreferences = false
private var _didRedirectToLogFile = false
private var _lastLogTimeInterval: NSTimeInterval = NSDate.timeIntervalSinceReferenceDate()
private var _logFile: UnsafeMutablePointer<FILE>?


private func _XUCachePreferences() {
	if !_didCachePreferences {
		_didCachePreferences = true
		_cachedPreferences = NSUserDefaults.standardUserDefaults().boolForKey(XULoggingEnabledDefaultsKey)
	}
}
private func _XURunningDevelopmentComputer() -> Bool {
	
	if XUAppSetup.isRunningInDebugMode {
		return true
	}
	
	#if TARGET_OS_SIMULATOR
		return true
	#endif
	
	return false
}
private func _XURedirectToLogFile() {
	// DO NOT LOG ANYTHING IN THIS FUNCTION,
	// AS YOU'D MAKE AN INFINITE LOOP!
	
	if _XURunningDevelopmentComputer() {
		return
	}
	
	let logFile = _XULogFilePath()
	
	// Try to create the log file
	if !NSFileManager.defaultManager().fileExistsAtPath(logFile) {
		NSData().writeToFile(logFile, atomically: true)
	}
	
	_logFile = fopen((logFile as NSString).fileSystemRepresentation, ("a+" as NSString).UTF8String)
	if _logFile != nil {
		let fileDesc = fileno(_logFile!)
		dup2(fileDesc, STDOUT_FILENO)
		dup2(fileDesc, STDERR_FILENO)
		
		setbuf(__stdoutp, nil)
		
		_didRedirectToLogFile = true
	}
}
private func _XUStartNewSession() {
	let processInfo = NSProcessInfo()
	
	let version = XUAppSetup.applicationVersionNumber
	let buildNumber = XUAppSetup.applicationBuildNumber
	
	print("\n\n\n============== Starting a new \(processInfo.processName) session (version \(version)[\(buildNumber)]) ==============")
}
private func _XULogInitializer() {
	if _didCachePreferences {
		// No double-initialization
		return
	}
	
	//Don't redirect the log on my computer
	if _XURunningDevelopmentComputer(){
		_didCachePreferences = true
		_cachedPreferences = true
		return
	}
	
	_XUCachePreferences()

	if _cachedPreferences {
		_XURedirectToLogFile()
		_XUStartNewSession()
	}
}

private func __XULogSetShouldLog(log: Bool) {
	if log && !_didRedirectToLogFile {
		_XURedirectToLogFile()
		_XUStartNewSession()
	}
	
	let didChange = log != _cachedPreferences;
	
	_cachedPreferences = log
	_didCachePreferences = true //Already cached hence
	
	if (didChange) {
		NSNotificationCenter.defaultCenter().postNotificationName(XULoggingStatusChangedNotification, object: nil)
	}
}

private func _XULogFilePath() -> String {
	let appIdentifier = XUAppSetup.applicationIdentifier
	
	let logFolder = ("~/Library/Application Support/\(appIdentifier)/Logs/" as NSString).stringByExpandingTildeInPath
	let logFile = logFolder + "/" + "\(appIdentifier).log"
	_ = try? NSFileManager.defaultManager().createDirectoryAtPath(logFolder, withIntermediateDirectories: true, attributes: nil)
	return logFile
}


/// Returns file path to the debug log.
@available(*, deprecated, message="If you need to clear the log, use XUClearLog, if you need to show it in Finder (OS X), use XUSelectDebugLogFileInFileViewer")
public func XULogFilePath() -> String {
	return _XULogFilePath()
}

#if os(OSX)

	/// Activates Finder and selects the debug log file.
	public func XUSelectDebugLogFileInFileViewer() {
		if _logFile != nil {
			fflush(__stdoutp)
			fflush(_logFile!)
		}
		
		NSWorkspace.sharedWorkspace().selectFile(_XULogFilePath(), inFileViewerRootedAtPath: "")
	}
	
	/// Opens the debug log in Console.
	public func XUOpenDebugLogInConsole() {
		if _logFile != nil {
			fflush(__stdoutp)
			fflush(_logFile!)
		}
		
		let URL = NSURL(fileURLWithPath: _XULogFilePath())
		NSWorkspace.sharedWorkspace().openURLs([URL], withAppBundleIdentifier: "com.apple.Console", options: .Default, additionalEventParamDescriptor: nil, launchIdentifiers: nil)
	}
	
#endif


/// Forces logging a string by temporarily enabling debug logging.
public func XUForceLog(@autoclosure string: () -> String, method: String = #function, file: String = #file, line: Int = #line) {
	let originalPreferences = _cachedPreferences
	_cachedPreferences = true
	XULog(string, method: method, file: file, line: line)
	_cachedPreferences = originalPreferences
}

/// Logs a message to the console.
public func XULog(@autoclosure string: () -> String, method: String = #function, file: String = #file, line: Int = #line) {
	if !_didCachePreferences {
		_XULogInitializer()
	}
	
	if _cachedPreferences {
		print("\((file as NSString).lastPathComponent):\(line).\(method): \(string())")
		
		_lastLogTimeInterval = NSDate.timeIntervalSinceReferenceDate()
	}
}

/// Returns true when the debug logging is currently turned on.
public func XULoggingEnabled() -> Bool {
	if !_didCachePreferences {
		_XULogInitializer()
	}
	
	return _cachedPreferences
}

/// Use this function to toggle debugging while the app is running. This method,
/// unlike XUForceSetDebugging also sets the option in user defaults.
public func XULoggingSetEnabled(enabled: Bool) {
	__XULogSetShouldLog(enabled)
	
	NSUserDefaults.standardUserDefaults().setBool(enabled, forKey: XULoggingEnabledDefaultsKey)
	NSUserDefaults.standardUserDefaults().synchronize()
}


/// Clears the log file.
public func XULogClear() {
	if (_logFile != nil){
		fclose(_logFile!);
		_logFile = nil;
		
		_ = try? NSFileManager.defaultManager().removeItemAtPath(_XULogFilePath())
		
		_didRedirectToLogFile = false
		
		if _cachedPreferences {
			_XURedirectToLogFile()
			_XUStartNewSession()
		}
	}
}

/// Returns a string containing current stacktrace.
public func XUStacktraceString() -> String {
	return NSThread.callStackSymbols().joinWithSeparator("\n")
}

/// Returns a string containing stacktrace of the exception.
public func XUStacktraceStringFromException(exception: NSException) -> String {
	return exception.callStackSymbols.joinWithSeparator("\n")
}

/// Logs current stacktrace with a comment.
public func XULogStacktrace(comment: String) {
	XULog("\(comment): \(XUStacktraceString())")
}


/// Do not use this class. It's a private class (which needs to be public so that
/// it can be seen from ObjC), that allows FCLog to inform XULog that the debug
/// logging preference was changed.
public class __XULogBridge: NSObject {
	
	/// This method must only be called by FCForceSetDebugLog().
	@available(*, deprecated, message="Migrate your code to Swift.")
	public class func setShouldLog(log: Bool) {
		__XULogSetShouldLog(log)
	}
	
	public class var stackTraceString: String {
		return XUStacktraceString()
	}
	
	public class func log(string: String) {
		if XULoggingEnabled() {
			print(string)
		}
	}
	
	@available(*, deprecated, message="Migrate your code to Swift.")
	public class var filePath: String {
		return _XULogFilePath()
	}
	
}



/// Deprecated methods.

@available(*, deprecated, renamed="XULogClear")
public func XUClearLog() {
	XULogClear()
}

/// Use this function to toggle debugging while the app is running.
@available(*, deprecated, message="Use XULoggingSetEnabled instead.")
public func XUForceSetDebugging(debug: Bool) {
	__XULogSetShouldLog(debug)
}

/// Returns true when the debug logging is currently turned on.
@available(*, deprecated, renamed="XULoggingEnabled")
public func XUShouldLog() -> Bool {
	return _cachedPreferences
}

@available(*, deprecated, message="Use XULoggingSetEnabled instead.")
public func XUSetLoggingEnabled(enabled: Bool) {
	XULoggingSetEnabled(enabled)
}


