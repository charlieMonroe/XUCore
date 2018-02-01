//
//  NSMenuLocalizationSupport.swift
//  XUCore
//
//  Created by Charlie Monroe on 11/7/15.
//  Copyright © 2015 Charlie Monroe Software. All rights reserved.
//

import Foundation


extension NSMenu: XULocalizableUIElement {
	
	public func localize(from bundle: Bundle = Bundle.main) {
		self.title = XULocalizedString(self.title)
		for item in self.items {
			if let attributedTitle = item.attributedTitle {
				let localizedTitle = XULocalizedString(attributedTitle.string, inBundle: bundle)
				let localizedAttributedTitle = NSAttributedString(string: localizedTitle, attributes: attributedTitle.attributes(at: 0, effectiveRange: nil))
				item.attributedTitle = localizedAttributedTitle
			}else{
				item.title = XULocalizedString(item.title, inBundle: bundle)
			}
			
			if item.hasSubmenu {
				item.submenu?.localize()
			}
		}
	}
	
	@available(*, deprecated, renamed: "localize(from:)")
	public func localizeMenu(_ bundle: Bundle = Bundle.main) {
		self.localize(from: bundle)
	}
	
}

