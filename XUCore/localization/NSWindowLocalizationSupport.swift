//
//  NSWindowLocalizationSupport.swift
//  XUCore
//
//  Created by Charlie Monroe on 11/7/15.
//  Copyright © 2015 Charlie Monroe Software. All rights reserved.
//

import Foundation

public extension NSWindow {
	
	public func localizeWindow(_ bundle: Bundle = XUMainBundle) {
		self.title = XULocalizedString(self.title, inBundle: bundle)
		
		self.contentView?.localizeView(bundle)
		
		if let toolbar = self.toolbar {
			for item in toolbar.items {
				item.label = XULocalizedString(item.label, inBundle: bundle)
			}
		}
	}
	
}
