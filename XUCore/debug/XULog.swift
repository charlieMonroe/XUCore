//
//  XULog.swift
//  XUCore
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


/// Forces logging a string by temporarily enabling debug logging.
public func XUForceLog(_ string: @autoclosure () -> String, method: String = #function, file: String = #file, line: Int = #line) {
	let originalPreferences = XUDebugLog._cachedPreferences
	XUDebugLog._cachedPreferences = true
	XULog(string, method: method, file: file, line: line)
	XUDebugLog._cachedPreferences = originalPreferences
}

/// Logs a message to the console.
public func XULog(_ string: @autoclosure () -> String, method: String = #function, file: String = #file, line: Int = #line) {
	if !XUDebugLog._didCachePreferences {
		XUDebugLog._initialize()
	}
	
	if XUDebugLog._cachedPreferences {
		print("\(file.components(separatedBy: "/").last.descriptionWithDefaultValue()):\(line).\(method): \(string())")
		
		XUDebugLog._lastLogTimeInterval = Date.timeIntervalSinceReferenceDate
	}
}

/// Returns a string containing current stacktrace.
public func XUStacktraceString() -> String {
	return Thread.callStackSymbols.joined(separator: "\n")
}

/// Returns a string containing stacktrace of the exception.
public func XUStacktraceStringFromException(_ exception: NSException) -> String {
	return exception.callStackSymbols.joined(separator: "\n")
}

/// Logs current stacktrace with a comment.
public func XULogStacktrace(_ comment: @autoclosure () -> String) {
	XULog("\(comment()): \(XUStacktraceString())")
}


/// A class with no initializer that has a few static methods to be used with
/// logging.
public final class XUDebugLog {
	
	fileprivate static var _cachedPreferences = false
	fileprivate static var _didCachePreferences = false
	fileprivate static var _didRedirectToLogFile = false
	fileprivate static var _lastLogTimeInterval: TimeInterval = Date.timeIntervalSinceReferenceDate
	fileprivate static var _logFile: UnsafeMutablePointer<FILE>?

	/// Clears the log file.
	public class func clearLog() {
		if (_logFile != nil){
			fclose(_logFile!);
			_logFile = nil;
			
			_ = try? FileManager.default.removeItem(atPath: self.logFilePath)
			
			_didRedirectToLogFile = false
			
			if _cachedPreferences {
				self._redirectToLogFile()
				self._startNewSession()
			}
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
			_didCachePreferences = true //Already cached hence
			
			if (didChange) {
				NotificationCenter.default.post(name: Notification.Name(rawValue: XULoggingStatusChangedNotification), object: nil)
			}
			
			UserDefaults.standard.set(newValue, forKey: XULoggingEnabledDefaultsKey)
			UserDefaults.standard.synchronize()
		}
	}
	
	fileprivate class var logFilePath: String {
		let appIdentifier = XUAppSetup.applicationIdentifier
		
		let logFolder = ("~/Library/Application Support/\(appIdentifier)/Logs/" as NSString).expandingTildeInPath
		let logFile = logFolder + "/" + "\(appIdentifier).log"
		_ = try? FileManager.default.createDirectory(atPath: logFolder, withIntermediateDirectories: true, attributes: nil)
		return logFile
	}
	
	#if os(OSX)
	
	/// Menu that contains all the necessary menu items to deal with the debug
	/// log. Use XUDebugLog.installDebugMenu() to install this menu into the
	/// menu bar next to the Help menu.
	public static let debugMenu: NSMenu = XUDebugLog._createDebugMenu()
	
	/// Installs the debug menu in the menu bar.
	public class func installDebugMenu() {
		let menuItem = NSMenuItem(title: XULocalizedString("Debug", inBundle: XUCore.bundle), action: nil, keyEquivalent: "")
		menuItem.submenu = self.debugMenu
		
		guard let mainMenu = NSApp?.mainMenu else {
			fatalError("Installing a debug menu before application is fully launched, or doesn't contain main menu.")
		}
		
		guard mainMenu.numberOfItems > 1 else {
			fatalError("Main menu is empty. Installing Debug menu requires at least one item.")
		}
		
		mainMenu.insertItem(menuItem, at: mainMenu.numberOfItems - 1)
	}
	
	/// Opens the debug log in Console.
	public class func openDebugLogInConsole() {
		if _logFile != nil {
			fflush(__stdoutp)
			fflush(_logFile!)
		}
		
		let url = URL(fileURLWithPath: XUDebugLog.logFilePath)
		NSWorkspace.shared().open([url], withAppBundleIdentifier: "com.apple.Console", options: .default, additionalEventParamDescriptor: nil, launchIdentifiers: nil)
	}
	
	/// Activates Finder and selects the debug log file.
	public class func selectDebugLogInFileViewer() {
		if _logFile != nil {
			fflush(__stdoutp)
			fflush(_logFile!)
		}
		
		NSWorkspace.shared().selectFile(XUDebugLog.logFilePath, inFileViewerRootedAtPath: "")
	}

	
	fileprivate static var _debugLoggingOn: NSMenuItem!
	fileprivate static var _debugLoggingOff: NSMenuItem!
	
	#endif
	
	
	fileprivate class func _cachePreferences() {
		if !_didCachePreferences {
			_didCachePreferences = true
			_cachedPreferences = UserDefaults.standard.bool(forKey: XULoggingEnabledDefaultsKey)
		}
	}
	
	fileprivate class var _isRunningDevelopmentComputer: Bool {
		if XUAppSetup.isRunningInDebugMode {
			return true
		}
		
		#if os(iOS) && (arch(i386) || arch(x86_64))
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
		
		let logFile = self.logFilePath
		
		// Try to create the log file
		if !FileManager.default.fileExists(atPath: logFile) {
			try? Data().write(to: URL(fileURLWithPath: logFile), options: [.atomic])
		}
		
		_logFile = fopen((logFile as NSString).fileSystemRepresentation, "a+")
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
		
		XULog("\n\n\n============== Starting a new session ==============")
		XULog("Application: \(processInfo.processName)")
		XULog("Version: \(version)[\(buildNumber)]")
		XULog("")
	}
	
}

#if os(OSX)
	
	private let _actionHandler = _XUDebugLogActionHandler()
	
	private final class _XUDebugLogActionHandler: NSObject {
		
		@objc fileprivate func _clearLog() {
			XUDebugLog.clearLog()
		}
		
		@objc fileprivate func _logAppState() {
			if let provider = XUAppSetup.applicationStateProvider {
				XULog(provider.provideApplicationState())
			}
		}
		
		@objc fileprivate func _showAboutDialog() {
			let alert = NSAlert()
			let appName = ProcessInfo().processName
			alert.messageText = XULocalizedFormattedString("Debug log is a text file that contains some technical details about what %@ performs in the background. It is fairly useful to me in order to fix things quickly since it allows me to see what's going on. To get the debug log, follow these simple steps:", appName, inBundle: XUCore.bundle)
			alert.informativeText = XULocalizedFormattedString("1) If this isn\'t your first debug log you are sending, please, select Clear Debug Log from the Debug menu.\n2) In the Debug menu, make sure that Debug Logging is On.\n3) Perform whatever task you are having issues with.\n4) In the Debug menu, turn Debug Logging Off.\n5) In the Debug menu, select Show Log in Finder. This selects the log file in Finder and you can easily send it to me. Please, attach the file to the email rather than copy-pasting the information.\n\nThe log file doesn\'t contain any personal data which can be verified by opening the log file (it is a simple text file). If you consider some of the data confidential or personal, please, replace them with something that can be easily identified as a placeholder (e.g. XXXXXXXX) and let me know that you\'ve modified the log file.", appName, inBundle: XUCore.bundle)
			alert.addButton(withTitle: XULocalizedString("OK", inBundle: XUCore.bundle))
			alert.runModal()
		}
		
		@objc fileprivate func _showLog() {
			XUDebugLog.selectDebugLogInFileViewer()
		}
		
		@objc fileprivate func _turnLoggingOn() {
			XUDebugLog.isLoggingEnabled = true
			
			XUDebugLog._debugLoggingOn.state = NSOnState
			XUDebugLog._debugLoggingOff.state = NSOffState
		}
		
		@objc fileprivate func _turnLoggingOff() {
			XUDebugLog.isLoggingEnabled = false
			
			XUDebugLog._debugLoggingOn.state = NSOffState
			XUDebugLog._debugLoggingOff.state = NSOnState
		}
		
	}
	
	public extension XUDebugLog {
		
		fileprivate class func _createDebugMenu() -> NSMenu {
			let menu = NSMenu(title: XULocalizedString("Debug", inBundle: XUCore.bundle))
			menu.addItem(withTitle: XULocalizedString("About Debug Log...", inBundle: XUCore.bundle), action: #selector(_XUDebugLogActionHandler._showAboutDialog), keyEquivalent: "").target = _actionHandler
			menu.addItem(NSMenuItem.separator())
			
			let loggingMenu = NSMenu(title: XULocalizedString("Debug Logging", inBundle: XUCore.bundle))
			XUDebugLog._debugLoggingOn = loggingMenu.addItem(withTitle: XULocalizedString("On", inBundle: XUCore.bundle), action: #selector(_XUDebugLogActionHandler._turnLoggingOn), keyEquivalent: "")
			XUDebugLog._debugLoggingOff = loggingMenu.addItem(withTitle: XULocalizedString("Off", inBundle: XUCore.bundle), action: #selector(_XUDebugLogActionHandler._turnLoggingOff), keyEquivalent: "")
			
			XUDebugLog._debugLoggingOn.target = _actionHandler
			XUDebugLog._debugLoggingOff.target = _actionHandler
			
			XUDebugLog._debugLoggingOn.state = self.isLoggingEnabled ? NSOnState : NSOffState
			XUDebugLog._debugLoggingOff.state = self.isLoggingEnabled ? NSOffState : NSOnState
			
			let loggingItem = menu.addItem(withTitle: XULocalizedString("Debug Logging", inBundle: XUCore.bundle), action: nil, keyEquivalent: "")
			loggingItem.submenu = loggingMenu
			
			menu.addItem(NSMenuItem.separator())
			
			if XUAppSetup.applicationStateProvider != nil {
				menu.addItem(withTitle: XULocalizedString("Log Current Application State", inBundle: XUCore.bundle), action: #selector(_XUDebugLogActionHandler._logAppState), keyEquivalent: "").target = _actionHandler
			}
			menu.addItem(withTitle: XULocalizedString("Clear Debug Log", inBundle: XUCore.bundle), action: #selector(_XUDebugLogActionHandler._clearLog), keyEquivalent: "").target = _actionHandler

			menu.addItem(NSMenuItem.separator())
			
			menu.addItem(withTitle: XULocalizedString("Show Log in Finder", inBundle: XUCore.bundle), action: #selector(_XUDebugLogActionHandler._showLog), keyEquivalent: "").target = _actionHandler
			
			return menu
		}

	}
#endif



/// Deprecated methods.

@available(*, deprecated, renamed: "XUDebugLog.isLoggingEnabled")
public func XULoggingSetEnabled(_ enabled: Bool) {
	XUDebugLog.isLoggingEnabled = enabled
}

@available(*, deprecated, renamed: "XUDebugLog.isLoggingEnabled")
public func XULoggingEnabled() -> Bool {
	return XUDebugLog.isLoggingEnabled
}

/// Returns file path to the debug log.
@available(*, deprecated, message: "If you need to clear the log, use XUClearLog, if you need to show it in Finder (OS X), use XUSelectDebugLogFileInFileViewer")
public func XULogFilePath() -> String {
	return XUDebugLog.logFilePath
}

@available(*, deprecated, renamed: "XUDebugLog.clearLog")
public func XUClearLog() {
	XULogClear()
}

@available(*, deprecated, renamed: "XUDebugLog.clearLog")
public func XULogClear() {
	XUDebugLog.clearLog()
}

/// Use this function to toggle debugging while the app is running.
@available(*, deprecated, message: "Use XULoggingSetEnabled instead.")
public func XUForceSetDebugging(_ debug: Bool) {
	XULoggingSetEnabled(debug)
}

/// Returns true when the debug logging is currently turned on.
@available(*, deprecated, renamed: "XULoggingEnabled")
public func XUShouldLog() -> Bool {
	return XULoggingEnabled()
}

@available(*, deprecated, message: "Use XULoggingSetEnabled instead.")
public func XUSetLoggingEnabled(_ enabled: Bool) {
	XULoggingSetEnabled(enabled)
}

#if os(OSX)
	@available(*, deprecated, renamed: "XUDebugLog.selectDebugLogInFileViewer")
	public func XUSelectDebugLogFileInFileViewer() {
		XUDebugLog.selectDebugLogInFileViewer()
	}
	
	@available(*, deprecated, renamed: "XUDebugLog.openDebugLogInConsole")
	public func XUOpenDebugLogInConsole() {
		XUDebugLog.openDebugLogInConsole()
	}

#endif


