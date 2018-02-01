//
//  NSWindowLocalizationSupport.swift
//  XUCore
//
//  Created by Charlie Monroe on 11/7/15.
//  Copyright © 2015 Charlie Monroe Software. All rights reserved.
//

import Foundation

extension NSWindow: XULocalizableUIElement {
	
	public func localize(from bundle: Bundle = Bundle.main) {
		self.title = XULocalizedString(self.title, inBundle: bundle)
		
		self.contentView?.localize(from: bundle)
		
		if let toolbar = self.toolbar {
			for item in toolbar.items {
				item.label = XULocalizedString(item.label, inBundle: bundle)
			}
		}
	}

	@available(*, deprecated, renamed: "localize(from:)")
	public func localizeWindow(_ bundle: Bundle = Bundle.main) {
		self.localize(from: bundle)
	}
}
