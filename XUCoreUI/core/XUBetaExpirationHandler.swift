//
//  XUBetaExpirationHandler.swift
//  XUCore
//
//  Created by Charlie Monroe on 1/20/16.
//  Copyright © 2016 Charlie Monroe Software. All rights reserved.
//

import AppKit
import XUCore

private extension XUPreferences.Key {
	static let BetaDidShowExpirationWarning = XUPreferences.Key(rawValue: "XUBetaDidShowExpirationWarning")
	static let LastBetaBuildNumber = XUPreferences.Key(rawValue: "XULastBetaBuildNumber")
	static let LastBetaTimestamp = XUPreferences.Key(rawValue: "XULastBetaTimestamp")
}

private extension XUPreferences {
	
	var betaDidShowExpirationWarning: Bool {
		get {
			return self.boolean(for: .BetaDidShowExpirationWarning)
		}
		nonmutating set {
			self.set(boolean: newValue, forKey: .BetaDidShowExpirationWarning)
		}
	}
	
	var lastBetaBuildNumber: Int {
		get {
			return self.integer(for: .LastBetaBuildNumber)
		}
		nonmutating set {
			self.set(integer: newValue, forKey: .LastBetaBuildNumber)
		}
	}
	
	var lastBetaTimestamp: Date? {
		get {
			return self.value(for: .LastBetaTimestamp)
		}
		nonmutating set {
			self.set(value: newValue, forKey: .LastBetaTimestamp)
		}
	}
	
}

public final class XUBetaExpirationHandler {
	
	public static let shared: XUBetaExpirationHandler = XUBetaExpirationHandler()
	
	/// Returns number of seconds left in the beta mode.
	public var expiresInSeconds: TimeInterval {
		guard let date = XUPreferences.shared.lastBetaTimestamp else {
			// We're missing date -> someone has tempered with the defaults.
			self._handleExpiration()
			return -1.0
		}
		
		let timeInterval = abs(Date().timeIntervalSince(date))
		return XUAppSetup.betaExpirationTimeInterval - timeInterval
	}
	
	private func _showFirstBetaLaunchDialog() {
		if NSApp == nil {
			NotificationCenter.default.addObserver(forName: NSApplication.didFinishLaunchingNotification, object: nil, queue: nil, using: { (_) -> Void in
				self._showFirstBetaLaunchDialog()
			})
			return
		}
		
		let alert = NSAlert()
		alert.messageText = XULocalizedFormattedString("Welcome to beta testing of %@.", ProcessInfo().processName, inBundle: .core)
		alert.informativeText = XULocalizedFormattedString("This is the first time you run a beta build %@.", XUAppSetup.applicationBuildNumber, inBundle: .core)
		alert.addButton(withTitle: "OK")
		alert.runModal()
	}
	
	@objc
	private func _showWarningAndScheduleOneHourExpiration() {
		if NSApp == nil {
			NotificationCenter.default.addObserver(self, selector: #selector(_showWarningAndScheduleOneHourExpiration), name: NSApplication.didFinishLaunchingNotification, object: nil)
			return
		}
		
		let alert = NSAlert()
		alert.messageText = XULocalizedString("This beta build will expire in less than an hour.", inBundle: .core)
		alert.informativeText = XULocalizedString("Please update your copy of this beta build.", inBundle: .core)
		alert.addButton(withTitle: "OK")
		alert.runModal()
		
		Timer.scheduledTimer(timeInterval: XUTimeInterval.hour, target: self, selector: #selector(XUBetaExpirationHandler._handleExpiration), userInfo: nil, repeats: false)
	}
	
	@objc
	private func _handleExpiration() {
		if NSApp == nil {
			NotificationCenter.default.addObserver(forName: NSApplication.didFinishLaunchingNotification, object: nil, queue: nil, using: { (_) -> Void in
				self._handleExpiration()
			})
			return
		}
		
		let alert = NSAlert()
		alert.messageText = XULocalizedFormattedString("This beta build of %@ has expired.", ProcessInfo().processName, inBundle: .core)
		alert.informativeText = XULocalizedFormattedString("Please download a new build.", inBundle: .core)
		alert.addButton(withTitle: "OK")
		alert.runModal()
		
		exit(0)
	}
	
	private init() {
		if !XUAppSetup.isBetaBuild {
			return
		}
		
		let currentBuildNumber = XUAppSetup.applicationBuildNumber.integerValue
		let lastBuildNumber = XUPreferences.shared.lastBetaBuildNumber
		
		if lastBuildNumber == currentBuildNumber {
			/// We're continuing to use the same beta build.
			
			/// The user may have not used the beta in a week and we don't simply
			/// want to cut him out of the app since he may simply want to update
			/// it (e.g. via Sparkle), but the expiration dialog would have prevented
			/// him to do so.
			let didShowWarning = XUPreferences.shared.betaDidShowExpirationWarning
			
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
		XUPreferences.shared.perform { (prefs) in
			prefs.betaDidShowExpirationWarning = false
			prefs.lastBetaBuildNumber = currentBuildNumber
			prefs.lastBetaTimestamp = Date()
		}
		
		// Show a dialog.
		self._showFirstBetaLaunchDialog()
	}
	
	
}
