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

public class XUBetaExpirationHandler: NSObject {
	
	public static let sharedExpirationHandler: XUBetaExpirationHandler = XUBetaExpirationHandler()
	
	/// Returns number of seconds left in the beta mode.
	public var expiresInSeconds: NSTimeInterval {
		let defaults = NSUserDefaults.standardUserDefaults()
		guard let date = defaults.objectForKey(XULastBetaTimestampDefaultsKey) as? NSDate else {
			// We're missing date -> someone has tempered with the defaults.
			self._handleExpiration()
			return -1.0
		}
		
		let timeInterval = abs(NSDate().timeIntervalSinceDate(date))
		return XUApplicationSetup.sharedSetup.betaExpirationTimeInterval - timeInterval
	}
	
	private func _showFirstBetaLaunchDialog() {
		if NSApp == nil {
			NSNotificationCenter.defaultCenter().addObserverForName(NSApplicationDidFinishLaunchingNotification, object: nil, queue: nil, usingBlock: { (_) -> Void in
				self._showFirstBetaLaunchDialog()
			})
			return
		}
		
		let alert = NSAlert()
		alert.messageText = XULocalizedFormattedString("Welcome to beta testing of %@.", NSProcessInfo().processName, inBundle: XUCoreBundle)
		alert.informativeText = XULocalizedFormattedString("This is the first time you run a beta build %@.", XUApplicationSetup.sharedSetup.applicationBuildNumber, inBundle: XUCoreBundle)
		alert.addButtonWithTitle("OK")
		alert.runModal()
	}
	
	private func _showWarningAndScheduleOneHourExpiration() {
		
	}
	
	@objc
	private func _handleExpiration() {
		if NSApp == nil {
			NSNotificationCenter.defaultCenter().addObserverForName(NSApplicationDidFinishLaunchingNotification, object: nil, queue: nil, usingBlock: { (_) -> Void in
				self._handleExpiration()
			})
			return
		}
		
		let alert = NSAlert()
		alert.messageText = XULocalizedFormattedString("This beta build of %@ has expired.", NSProcessInfo().processName, inBundle: XUCoreBundle)
		alert.informativeText = XULocalizedFormattedString("Please download a new build.", inBundle: XUCoreBundle)
		alert.addButtonWithTitle("OK")
		alert.runModal()
		
		exit(0)
	}
	
	private override init() {
		super.init()
		
		if !XUApplicationSetup.sharedSetup.isBetaBuild {
			return
		}
		
		let defaults = NSUserDefaults.standardUserDefaults()
		let currentBuildNumber = XUApplicationSetup.sharedSetup.applicationBuildNumber.integerValue
		
		if let number = defaults.objectForKey(XULastBetaBuildNumberDefaultsKey) as? NSNumber where number.integerValue == currentBuildNumber {
			/// We're continuing to use the same beta build.
			
			/// The user may have not used the beta in a week and we don't simply
			/// want to cut him out of the app since he may simply want to update
			/// it (e.g. via Sparkle), but the expiration dialog would have prevented
			/// him to do so.
			let didShowWarning = defaults.boolForKey(XUBetaDidShowExpirationWarningDefaultsKey)
			
			let timeInterval = self.expiresInSeconds
			
			// The beta will expire in less than an hour and we haven't shown 
			// a warning yet - do so now.
			if timeInterval < 3600.0 && !didShowWarning {
				self._showWarningAndScheduleOneHourExpiration()
				return
			}
					
			if timeInterval < 0 {
				self._handleExpiration()
				
				// No return
			}
			
			NSTimer.scheduledTimerWithTimeInterval(timeInterval, target: self, selector: #selector(XUBetaExpirationHandler._handleExpiration), userInfo: nil, repeats: false)
			return
		}
		
		// First use with this build number.
		defaults.setBool(false, forKey: XUBetaDidShowExpirationWarningDefaultsKey)
		defaults.setObject(NSNumber(integer: currentBuildNumber), forKey: XULastBetaBuildNumberDefaultsKey)
		defaults.setObject(NSDate(), forKey: XULastBetaTimestampDefaultsKey)
		defaults.synchronize()
		
		// Show a dialog.
		self._showFirstBetaLaunchDialog()
	}
	
	
}
