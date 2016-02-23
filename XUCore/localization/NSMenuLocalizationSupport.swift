//
//  NSMenuLocalizationSupport.swift
//  XUCore
//
//  Created by Charlie Monroe on 11/7/15.
//  Copyright © 2015 Charlie Monroe Software. All rights reserved.
//

import Foundation


public extension NSMenu {
	
	public func localizeMenu(bundle: NSBundle = XUMainBundle) {
		self.title = XULocalizedString(self.title)
		for item in self.itemArray {
			if let attributedTitle = item.attributedTitle {
				let localizedTitle = XULocalizedString(attributedTitle.string, inBundle: bundle)
				let localizedAttributedTitle = NSAttributedString(string: localizedTitle, attributes: attributedTitle.attributesAtIndex(0, effectiveRange: nil))
				item.attributedTitle = localizedAttributedTitle
			}else{
				item.title = XULocalizedString(item.title, inBundle: bundle)
			}
			
			if item.hasSubmenu {
				item.submenu?.localizeMenu()
			}
		}
	}
	
}

