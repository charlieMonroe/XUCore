//
//  XUBetaExpirationHandler.swift
//  XUCore
//
//  Created by Charlie Monroe on 1/20/16.
//  Copyright © 2016 Charlie Monroe Software. All rights reserved.
//

import Foundation

private let XUBetaDidShowExpirationWarningDefaultsKey = "XUBetaDidShowExpirationWarning"
private let XULastBetaBuildNumberDefaultsKey = "XULastBetaBuildNumber"
private let XULastBetaTimestampDefaultsKey = "XULastBetaTimestamp"

public final class XUBetaExpirationHandler {
	
	public static let sharedExpirationHandler: XUBetaExpirationHandler = XUBetaExpirationHandler()
	
	/// Returns number of seconds left in the beta mode.
	public var expiresInSeconds: TimeInterval {
		let defaults = UserDefaults.standard
		guard let date = defaults.object(forKey: XULastBetaTimestampDefaultsKey) as? Date else {
			// We're missing date -> someone has tempered with the defaults.
			self._handleExpiration()
			return -1.0
		}
		
		let timeInterval = abs(Date().timeIntervalSince(date))
		return XUAppSetup.betaExpirationTimeInterval - timeInterval
	}
	
	fileprivate func _showFirstBetaLaunchDialog() {
		if NSApp == nil {
			NotificationCenter.default.addObserver(forName: .NSApplicationDidFinishLaunching, object: nil, queue: nil, using: { (_) -> Void in
				self._showFirstBetaLaunchDialog()
			})
			return
		}
		
		let alert = NSAlert()
		alert.messageText = XULocalizedFormattedString("Welcome to beta testing of %@.", ProcessInfo().processName, inBundle: XUCoreFramework.bundle)
		alert.informativeText = XULocalizedFormattedString("This is the first time you run a beta build %@.", XUAppSetup.applicationBuildNumber, inBundle: XUCoreFramework.bundle)
		alert.addButton(withTitle: "OK")
		alert.runModal()
	}
	
	@objc
	fileprivate func _showWarningAndScheduleOneHourExpiration() {
		if NSApp == nil {
			NotificationCenter.default.addObserver(self, selector: #selector(_showWarningAndScheduleOneHourExpiration), name: .NSApplicationDidFinishLaunching, object: nil)
			return
		}
		
		let alert = NSAlert()
		alert.messageText = XULocalizedString("This beta build will expire in less than an hour.", inBundle: XUCoreFramework.bundle)
		alert.informativeText = XULocalizedString("Please update your copy of this beta build.", inBundle: XUCoreFramework.bundle)
		alert.addButton(withTitle: "OK")
		alert.runModal()
		
		Timer.scheduledTimer(timeInterval: XUTimeInterval.hour, target: self, selector: #selector(XUBetaExpirationHandler._handleExpiration), userInfo: nil, repeats: false)
	}
	
	@objc
	fileprivate func _handleExpiration() {
		if NSApp == nil {
			NotificationCenter.default.addObserver(forName: NSNotification.Name.NSApplicationDidFinishLaunching, object: nil, queue: nil, using: { (_) -> Void in
				self._handleExpiration()
			})
			return
		}
		
		let alert = NSAlert()
		alert.messageText = XULocalizedFormattedString("This beta build of %@ has expired.", ProcessInfo().processName, inBundle: XUCoreFramework.bundle)
		alert.informativeText = XULocalizedFormattedString("Please download a new build.", inBundle: XUCoreFramework.bundle)
		alert.addButton(withTitle: "OK")
		alert.runModal()
		
		exit(0)
	}
	
	fileprivate init() {
		if !XUAppSetup.isBetaBuild {
			return
		}
		
		let defaults = UserDefaults.standard
		let currentBuildNumber = XUAppSetup.applicationBuildNumber.integerValue
		
		if let number = defaults.object(forKey: XULastBetaBuildNumberDefaultsKey) as? NSNumber , number.intValue == currentBuildNumber {
			/// We're continuing to use the same beta build.
			
			/// The user may have not used the beta in a week and we don't simply
			/// want to cut him out of the app since he may simply want to update
			/// it (e.g. via Sparkle), but the expiration dialog would have prevented
			/// him to do so.
			let didShowWarning = defaults.bool(forKey: XUBetaDidShowExpirationWarningDefaultsKey)
			
			let timeInterval = self.expiresInSeconds
			
			// The beta will expire in less than an hour and we haven't shown 
			// a warning yet - do so now.
			if timeInterval < XUTimeInterval.hour && !didShowWarning {
				self._showWarningAndScheduleOneHourExpiration()
				return
			}
					
			if timeInterval < 0 {
				self._handleExpiration()
				
				// No return
			}
			
			Timer.scheduledTimer(timeInterval: timeInterval, target: self, selector: #selector(XUBetaExpirationHandler._handleExpiration), userInfo: nil, repeats: false)
			return
		}
		
		// First use with this build number.
		defaults.set(false, forKey: XUBetaDidShowExpirationWarningDefaultsKey)
		defaults.set(NSNumber(value: currentBuildNumber as Int), forKey: XULastBetaBuildNumberDefaultsKey)
		defaults.set(Date(), forKey: XULastBetaTimestampDefaultsKey)
		defaults.synchronize()
		
		// Show a dialog.
		self._showFirstBetaLaunchDialog()
	}
	
	
}
