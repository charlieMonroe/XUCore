//
//  XULog.swift
//  XUCore
//
//  Created by Charlie Monroe on 10/28/15.
//  Copyright © 2015 Charlie Monroe Software. All rights reserved.
//

import Foundation

#if os(macOS)
	import Cocoa
#endif

private extension XUPreferences.Key {

	/// We are not exposing this defaults key. Please, use XULoggingEnabled() function
	/// and XUSetLoggingEnabled().
	static let LoggingEnabled = XUPreferences.Key(rawValue: "XULoggingEnabled")
	
}

extension XUPreferences {
	
	var isLoggingEnabled: Bool {
		get {
			return self.boolean(for: .LoggingEnabled)
		}
		nonmutating set {
			self.set(boolean: newValue, forKey: .LoggingEnabled)
		}
	}
	
}


/// Forces logging a string by temporarily enabling debug logging.
public func XUForceLog(_ string: @autoclosure () -> String, method: String = #function, file: String = #file, line: Int = #line) {
	let originalPreferences = XUDebugLog._cachedPreferences
	XUDebugLog._cachedPreferences = true
	XULog(string, method: method, file: file, line: line)
	XUDebugLog._cachedPreferences = originalPreferences
}

/// Logs a message to the console.
///
/// It automatically gathers the method, file and line. You can optionally wrap
/// the logged string to a certain width and apply indentation level. Spaces
/// are used for indentation (4 spaces per level).
public func XULog(_ string: @autoclosure () -> String, method: String = #function, file: String = #file, line: Int = #line, wrappedToWidth: Int? = nil, indentationLevel: Int = 0) {
	if !XUDebugLog._didCachePreferences {
		XUDebugLog._initialize()
	}
	
	guard XUDebugLog._cachedPreferences else {
		return
	}
	
	if Date.timeIntervalSinceReferenceDate - XUDebugLog._lastLogTimeInterval > XUTimeInterval.minute {
		print("\(XUDebugLog._dateFormatter.string(from: Date())):\n")
	}
	
	var logString = string()
	
	if let width = wrappedToWidth {
		logString = logString.wrapped(to: width)
	}
	
	if indentationLevel != 0 {
		let prefix = String(Array<Character>(repeating: Character(" "), count: indentationLevel * 4))
		logString = logString.lines.map({ prefix + $0 }).joined(separator: "\n")
	}
	
	print("\(file.components(separatedBy: "/").last.descriptionWithDefaultValue()):\(line).\(method): \(logString)")
	
	XUDebugLog._lastLogTimeInterval = Date.timeIntervalSinceReferenceDate
}

/// Returns a string containing current stacktrace.
public func XUStacktraceString() -> String {
	return Thread.callStackSymbols.joined(separator: "\n")
}

/// Returns a string containing stacktrace of the exception.
public func XUStacktraceString(from exception: NSException) -> String {
	return exception.callStackSymbols.joined(separator: "\n")
}

/// Logs current stacktrace with a comment.
public func XULogStacktrace(_ comment: @autoclosure () -> String) {
	XULog("\(comment()): \(XUStacktraceString())")
}


/// A class with no initializer that has a few static methods to be used with
/// logging.
public final class XUDebugLog {
	
	/// Posted when the debug log status changes.
	public static let StatusDidChangeNotification = Notification.Name(rawValue: "XULoggingStatusChangedNotification")
	
	fileprivate static var _cachedPreferences = false
	fileprivate static let _dateFormatter: DateFormatter = {
		let formatter = DateFormatter()
		formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
		return formatter
	}()
	fileprivate static var _didCachePreferences = false
	fileprivate static var _didRedirectToLogFile = false
	
	private static var __lastLogTimeIntervalBacking: TimeInterval = Date.distantPast.timeIntervalSinceReferenceDate
	private static var _logLock: NSRecursiveLock = NSRecursiveLock(name: "com.charliemonroe.XULog")
	
	fileprivate static var _lastLogTimeInterval: TimeInterval {
		get {
			_logLock.lock()
			defer {
				_logLock.unlock()
			}
			
			return __lastLogTimeIntervalBacking
		}
		set {
			_logLock.perform {
				__lastLogTimeIntervalBacking = newValue
			}
		}
	}
	
	fileprivate static var _logFile: UnsafeMutablePointer<FILE>?

	/// Clears the log file.
	public class func clearLog() {
		if (_logFile != nil){
			fclose(_logFile!);
			_logFile = nil;
			
			_ = try? FileManager.default.removeItem(at: self.logFileURL)
			
			_didRedirectToLogFile = false
			
			if _cachedPreferences {
				self._redirectToLogFile()
				self._startNewSession()
			}
		}
	}
	
	/// Flushes the log file.
	public class func flushLog() {
		if _logFile != nil {
			fflush(__stdoutp)
			fflush(_logFile!)
		}
	}
	
	/// Get or set whether logging is enabled.
	///
	/// Use this property to toggle debugging while the app is running. This property,
	/// unlike XUForceSetDebugging, also sets the option in user defaults.
	public class var isLoggingEnabled: Bool {
		get {
			if !_didCachePreferences {
				self._initialize()
			}
			
			return _cachedPreferences
		}
		set {
			if newValue && !_didRedirectToLogFile {
				self._redirectToLogFile()
				self._startNewSession()
			}
			
			let didChange = newValue != _cachedPreferences;
			
			_cachedPreferences = newValue
			_didCachePreferences = true // Already cached hence
			
			if didChange {
				NotificationCenter.default.post(name: XUDebugLog.StatusDidChangeNotification, object: nil)
			}
			
			XUPreferences.shared.perform { (prefs) in
				prefs.isLoggingEnabled = newValue
			}
		}
	}
	
	/// The log file URL.
	public static let logFileURL: URL = {
		let appIdentifier = XUAppSetup.applicationIdentifier
		
		let logFolder = FileManager.Directories.applicationSupportDirectory.appendingPathComponents(appIdentifier, "Logs")
		let logFile = logFolder.appendingPathComponent("\(appIdentifier).log")
		FileManager.default.createDirectory(at: logFolder)
		
		return logFile
	}()
	
	fileprivate class func _cachePreferences() {
		if !_didCachePreferences {
			_didCachePreferences = true
			_cachedPreferences = XUPreferences.shared.isLoggingEnabled
		}
	}
	
	fileprivate class var _isRunningDevelopmentComputer: Bool {
		if XUAppSetup.isRunningInDebugMode {
			return true
		}
		
		#if targetEnvironment(simulator)
			return true
		#else
			return false
		#endif
	}
	
	fileprivate class func _initialize() {
		if _didCachePreferences {
			// No double-initialization
			return
		}
		
		//Don't redirect the log on my computer
		if self._isRunningDevelopmentComputer {
			_didCachePreferences = true
			_cachedPreferences = true
			return
		}
		
		self._cachePreferences()
		
		if _cachedPreferences {
			self._redirectToLogFile()
			self._startNewSession()
		}
	}
	
	fileprivate class func _redirectToLogFile() {
		// DO NOT LOG ANYTHING IN THIS FUNCTION,
		// AS YOU'D MAKE AN INFINITE LOOP!
		
		if self._isRunningDevelopmentComputer {
			return
		}
		
		let logFile = self.logFileURL
		
		// Try to create the log file
		if !FileManager.default.fileExists(atPath: logFile.path) {
			try? Data().write(to: logFile, options: [.atomic])
		}
		
		_logFile = fopen((logFile.path as NSString).fileSystemRepresentation, "a+")
		if _logFile != nil {
			let fileDesc = fileno(_logFile!)
			dup2(fileDesc, STDOUT_FILENO)
			dup2(fileDesc, STDERR_FILENO)
			
			setbuf(__stdoutp, nil)
			
			_didRedirectToLogFile = true
		}
	}
	
	fileprivate class func _startNewSession() {
		let processInfo = ProcessInfo()
		
		let version = XUAppSetup.applicationVersionNumber
		let buildNumber = XUAppSetup.applicationBuildNumber
		
		let formatter = DateFormatter()
		formatter.dateStyle = .short
		formatter.timeStyle = .short
		formatter.locale = Locale(identifier: "en-US")
		
		XULog("\n\n\n============== Starting a new session [\(formatter.string(from: Date()))] ==============")
		XULog("Application: \(processInfo.processName)")
		XULog("Version: \(version)[\(buildNumber)]")
		XULog("")
	}
	
}

/// Returns file path to the debug log.
@available(*, deprecated, message: "Use XUDebugLog.logFileURL")
/// Currently required for iOS, but is going away.
public func XULogFilePath() -> String {
	return XUDebugLog.logFileURL.path
}
