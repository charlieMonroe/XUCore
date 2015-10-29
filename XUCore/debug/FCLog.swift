//
//  FCLog.swift
//  DownieCore
//
//  Created by Charlie Monroe on 10/28/15.
//  Copyright © 2015 Charlie Monroe Software. All rights reserved.
//

import Cocoa

let FCLoggingStatusChangedNotification = "FCLoggingStatusChangedNotification"

private var _cachedPreferences = false
private var _didCachePreferences = false
private var _didRedirectToLogFile = false
private var _lastLogTimeInterval: NSTimeInterval = NSDate.timeIntervalSinceReferenceDate()
private var _logFile: UnsafeMutablePointer<FILE>?


private func _FCCachePreferences() {
	if !_didCachePreferences {
		_didCachePreferences = true
		_cachedPreferences = NSUserDefaults.standardUserDefaults().boolForKey("FCLoggingEnabled")
	}
}
private func _FCRunningDevelopmentComputer() -> Bool {
	#if DEBUG
		return true
	#endif
	#if TARGET_OS_SIMULATOR
		return true
	#endif
	
	if let PWD = NSProcessInfo().environment["PWD"] {
		return PWD.hasPrefix("/Users/charliemonroe/")
	}
	
	return false
}
private func _FCRedirectToLogFile() {
	// DO NOT LOG ANYTHING IN THIS FUNCTION,
	// AS YOU'D MAKE AN INFINITE LOOP!
	
	if _FCRunningDevelopmentComputer() {
		return
	}
	
	let logFile = FCLogFilePath()
	
	// Try to create the log file
	if !NSFileManager.defaultManager().fileExistsAtPath(logFile) {
		NSData().writeToFile(logFile, atomically: true)
	}
	
	_logFile = fopen((logFile as NSString).fileSystemRepresentation, ("a+" as NSString).UTF8String)
	if _logFile != nil {
		let fileDesc = fileno(_logFile!)
		dup2(fileDesc, STDOUT_FILENO)
		dup2(fileDesc, STDERR_FILENO)
		_didRedirectToLogFile = true
	}
}
private func _FCStartNewSession() {
	let processInfo = NSProcessInfo()
	let mainBundle = NSBundle.mainBundle()
	
	let version = mainBundle.objectForInfoDictionaryKey("CFBundleShortVersionString") as? String ?? "1.0"
	let buildNumber = mainBundle.objectForInfoDictionaryKey("CFBundleVersion") as? String ?? "0"
	
	print("\n\n\n============== Starting a new \(processInfo.processName) session (version \(version)[\(buildNumber)]) ==============")
}
private func _FCLogInitializer() {
	if _didCachePreferences {
		// No double-initialization
		return
	}
	
	//Don't redirect the log on my computer
	if _FCRunningDevelopmentComputer(){
		_didCachePreferences = true
		_cachedPreferences = true
		return
	}
	
	_FCCachePreferences()

	if _cachedPreferences {
		_FCRedirectToLogFile()
		_FCStartNewSession()
	}
}


func FCLogFilePath() -> String {
	let appIdentifier = NSBundle.mainBundle().bundleIdentifier ?? NSProcessInfo().processName
	
	let logFolder = ("~/Library/Application Support/\(appIdentifier)/Logs/" as NSString).stringByExpandingTildeInPath
	let logFile = logFolder + "/" + "\(appIdentifier).log"
	_ = try? NSFileManager.defaultManager().createDirectoryAtPath(logFolder, withIntermediateDirectories: true, attributes: nil)
	return logFile
}

func FCForceLog(@autoclosure string: () -> String, method: String = __FUNCTION__, file: String = __FILE__, line: Int = __LINE__) {
	let originalPreferences = _cachedPreferences
	_cachedPreferences = true
	FCLog(string, method: method, file: file, line: line)
	_cachedPreferences = originalPreferences
}

func FCLog(@autoclosure string: () -> String, method: String = __FUNCTION__, file: String = __FILE__, line: Int = __LINE__) {
	if !_didCachePreferences {
		_FCLogInitializer()
	}
	
	if _cachedPreferences {
		print("\((file as NSString).lastPathComponent):\(line).\(method): \(string())")
		
		_lastLogTimeInterval = NSDate.timeIntervalSinceReferenceDate()
	}
}

func FCForceSetDebugging(debug: Bool) {
	if debug && !_didRedirectToLogFile {
		_FCRedirectToLogFile()
		_FCStartNewSession()
	}
	
	let didChange = debug != _cachedPreferences;
	
	_cachedPreferences = debug
	_didCachePreferences = true //Already cached hence
	
	if (didChange) {
		NSNotificationCenter.defaultCenter().postNotificationName(FCLoggingStatusChangedNotification, object: nil)
	}
}
func FCShouldLog() -> Bool {
	return _cachedPreferences
}

func FCClearLog() {
	if (_logFile != nil){
		fclose(_logFile!);
		_logFile = nil;
		
		_ = try? NSFileManager.defaultManager().removeItemAtPath(FCLogFilePath())
		
		_didRedirectToLogFile = false
		
		if _cachedPreferences {
			_FCRedirectToLogFile()
			_FCStartNewSession()
		}
	}
}
