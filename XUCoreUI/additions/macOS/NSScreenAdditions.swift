//
//  NSScreenAdditions.swift
//  XUCoreUI
//
//  Created by Charlie Monroe on 4/25/22.
//  Copyright © 2022 Charlie Monroe Software. All rights reserved.
//

import AppKit
import Foundation

extension NSScreen {
	
	/// Returns current screen. This is done via several heuristics:
	///  - if there is only one screen (or none) available, that one is returned
	///  - if there are more screens and there's a key window, the screen of that window is used
	///  - if there is no key window, main window is used
	///  - if there is no key and no main window, then we use the mouse location on screen
	///  - if that doesn't help, we try to use NSApp.orderedWindows
	///  - we give up and return NSScreen.main or the first screen.
	public static var current: NSScreen? {
		let screens = self.screens
		guard screens.count > 1 else {
			return screens.first
		}
		
		if
			let window = NSApp.keyWindow ?? NSApp.mainWindow,
			let screen = window.screen
		{
			return screen
		}
		
		let mouseLocation = NSEvent.mouseLocation
		if let screen = screens.first(where: { $0.frame.contains(mouseLocation) }) {
			return screen
		}
		
		if let screen = NSApp.orderedWindows.compactMap(\.screen).first {
			return screen
		}
		
		return self.main ?? screens.first
	}
	
}
