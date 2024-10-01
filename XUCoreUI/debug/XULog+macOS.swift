//
//  XULog+macOS.swift
//  XUCoreUI
//
//  Created by Charlie Monroe on 3/20/19.
//  Copyright © 2019 Charlie Monroe Software. All rights reserved.
//

import AppKit
import Foundation
import XUCore

extension XUDebugLog {
	
	/// Menu that contains all the necessary menu items to deal with the debug
	/// log. Use XUDebugLog.installDebugMenu() to install this menu into the
	/// menu bar next to the Help menu.
	public static let debugMenu: NSMenu = XUDebugLog.createDebugMenu()
	
	/// Installs the debug menu in the menu bar.
	public class func installDebugMenu() {
		let menuItem = NSMenuItem(title: Localized("Debug", in: .core), action: nil, keyEquivalent: "")
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
		self.flushLog()
		
		guard let consoleURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.Console") else {
			XULog("Cannot locate Console!")
			return
		}
		
		NSWorkspace.shared.open([self.logFileURL], withApplicationAt: consoleURL, configuration: NSWorkspace.OpenConfiguration())
	}
	
	/// Activates Finder and selects the debug log file.
	public class func selectDebugLogInFileViewer() {
		self.flushLog()
		
		NSWorkspace.shared.activateFileViewerSelecting([self.logFileURL])
	}
		
}


private let _actionHandler = _XUDebugLogActionHandler()

/// Needs to be NSObject subclass due to OS X 10.11 - calling setTarget: on
/// NSMenuItem calls methodForSelector: which is implemented by NSObject.
private final class _XUDebugLogActionHandler: NSObject {
	
	@objc fileprivate func _clearLog() {
		XUDebugLog.clearLog()
	}
	
	@objc fileprivate func _copyAppState() {
		if let provider = XUAppSetup.applicationStateProvider {
			let state = provider.provideApplicationState()
			let pboard = NSPasteboard.general
			pboard.declareTypes([.string], owner: self)
			pboard.setString(state, forType: .string)
			
			let notification = XUSystemNotification(confirmationMessage: Localized("Copied"))
			XUSystemNotificationCenter.shared.showNotification(notification)
		}
	}
	
	@objc fileprivate func _logAppState() {
		if let provider = XUAppSetup.applicationStateProvider {
			XULog(provider.provideApplicationState())
		}
	}
	
	@objc fileprivate func _showAboutDialog() {
		let alert = NSAlert()
		let appName = ProcessInfo().processName
		alert.messageText = Localized("Debug log is a text file that contains some technical details about what %@ performs in the background. It is fairly useful to me in order to fix things quickly since it allows me to see what's going on. To get the debug log, follow these simple steps:", appName, in: .core)
		alert.informativeText = Localized("1) If this isn't your first debug log you are sending, please, select Clear Debug Log from the Debug menu.\n2) In the Debug menu, make sure that Debug Logging is On.\n3) Perform whatever task you are having issues with.\n4) In the Debug menu, turn Debug Logging Off.\n5) In the Debug menu, select Show Log in Finder. This selects the log file in Finder and you can easily send it to me. Please, attach the file to the email rather than copy-pasting the information.\n\nThe log file doesn't contain any personal data which can be verified by opening the log file (it is a simple text file). If you consider some of the data confidential or personal, please, replace them with something that can be easily identified as a placeholder (e.g. XXXXXXXX) and let me know that you've modified the log file.", appName, in: .core)
		alert.addButton(withTitle: Localized("OK", in: .core))
		alert.runModal()
	}
	
	@objc fileprivate func _showLog() {
		XUDebugLog.selectDebugLogInFileViewer()
	}
	
	@objc fileprivate func _turnLoggingOn(_ sender: NSMenuItem) {
		sender.menu!.items[0].state = .on
		sender.menu!.items[1].state = .off
		
		XUDebugLog.isLoggingEnabled = true
		
		self._logAppState()
	}
	
	@objc fileprivate func _turnLoggingOff(_ sender: NSMenuItem) {
		sender.menu!.items[0].state = .off
		sender.menu!.items[1].state = .on
		
		XUDebugLog.isLoggingEnabled = false
	}
	
}

extension XUDebugLog {
	
	/// Creates a new debug menu.
	public static func createDebugMenu() -> NSMenu {
		let menu = NSMenu(title: Localized("Debug", in: .core))
		menu.addItem(withTitle: Localized("About Debug Log...", in: .core), action: #selector(_XUDebugLogActionHandler._showAboutDialog), keyEquivalent: "").target = _actionHandler
		menu.addItem(NSMenuItem.separator())
		
		let loggingMenu = NSMenu(title: Localized("Debug Logging", in: .core))
		let debugLoggingOn = loggingMenu.addItem(withTitle: Localized("On", in: .core), action: #selector(_XUDebugLogActionHandler._turnLoggingOn), keyEquivalent: "")
		let debugLoggingOff = loggingMenu.addItem(withTitle: Localized("Off", in: .core), action: #selector(_XUDebugLogActionHandler._turnLoggingOff), keyEquivalent: "")
		
		debugLoggingOn.target = _actionHandler
		debugLoggingOff.target = _actionHandler
		
		debugLoggingOn.state = self.isLoggingEnabled ? .on : .off
		debugLoggingOff.state = self.isLoggingEnabled ? .off : .on
		
		let loggingItem = menu.addItem(withTitle: Localized("Debug Logging", in: .core), action: nil, keyEquivalent: "")
		loggingItem.submenu = loggingMenu
		
		menu.addItem(NSMenuItem.separator())
		
		if XUAppSetup.applicationStateProvider != nil {
			menu.addItem(withTitle: Localized("Copy Current Application State", in: .core), action: #selector(_XUDebugLogActionHandler._copyAppState), keyEquivalent: "").target = _actionHandler
			menu.addItem(withTitle: Localized("Log Current Application State", in: .core), action: #selector(_XUDebugLogActionHandler._logAppState), keyEquivalent: "").target = _actionHandler
		}
		menu.addItem(withTitle: Localized("Clear Debug Log", in: .core), action: #selector(_XUDebugLogActionHandler._clearLog), keyEquivalent: "").target = _actionHandler
		
		menu.addItem(NSMenuItem.separator())
		
		menu.addItem(withTitle: Localized("Show Log in Finder", in: .core), action: #selector(_XUDebugLogActionHandler._showLog), keyEquivalent: "").target = _actionHandler
		
		return menu
	}
	
}

