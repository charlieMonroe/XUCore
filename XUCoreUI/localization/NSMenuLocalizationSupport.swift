//
//  NSMenuLocalizationSupport.swift
//  XUCore
//
//  Created by Charlie Monroe on 11/7/15.
//  Copyright © 2015 Charlie Monroe Software. All rights reserved.
//

import AppKit
import Foundation
import XUCore

extension NSApplication {
	
	/// Localizes main menu and takes localizations from the MainMenu.strings
	/// table within XUCore. The localizations use an <AppName> placeholder for
	/// the name of the app as well. Values that are not contained in this localization
	/// are attempted to be localized using Localized from the main bundle.
	public func localizeMainMenu() {
		// TODO: move the localization files into CoreUI
		let bundle = Bundle.core
		let dict: [String : String]
		if
			let localizationURL = bundle.url(forResource: "MainMenu", withExtension: "strings", subdirectory: nil, localization: XULocalizationCenter.shared.localizationIdentifier(for: bundle)),
			var dictionary = NSDictionary(contentsOf: localizationURL) as? [String : String]
		{
			let appNamePlaceholder = "<AppName>"
			let appName = ProcessInfo().processName
			for (key, value) in dictionary {
				if key.contains(appNamePlaceholder) {
					dictionary[key.replacingOccurrences(of: appNamePlaceholder, with: appName)] = value.replacingOccurrences(of: appNamePlaceholder, with: appName)
				}
			}
			
			dict = dictionary
		} else {
			dict = [:]
		}
		
		self.mainMenu?._localize(using: { dict[$0] ?? Localized($0) })
	}
	
}

extension NSMenu: @retroactive XULocalizableUIElement {
	
	/// Localizes the menu using a custom localization function.
	fileprivate func _localize(using localizator: (String) -> String) {
		self.title = localizator(self.title)
		for item in self.items {
			if let attributedTitle = item.attributedTitle {
				let localizedTitle = localizator(attributedTitle.string)
				let localizedAttributedTitle = NSAttributedString(string: localizedTitle, attributes: attributedTitle.attributes(at: 0, effectiveRange: nil))
				item.attributedTitle = localizedAttributedTitle
			} else {
				if item.title == "Preferences…" || item.title == "Preferences...", #available(macOS 13.0, *) {
					item.title = Localized("Settings...", in: .core)
				} else {
					item.title = localizator(item.title)
				}
			}
			
			if item.hasSubmenu {
				item.submenu?._localize(using: localizator)
			}
		}
	}
	
	public func localize(from bundle: Bundle = Bundle.main) {
		self._localize(using: { Localized($0, in: bundle) })
	}
		
}

