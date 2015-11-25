//
//  NSWindowLocalizationSupport.swift
//  XUCore
//
//  Created by Charlie Monroe on 11/7/15.
//  Copyright © 2015 Charlie Monroe Software. All rights reserved.
//

import Foundation

public extension NSWindow {
	
	public func localizeWindow() {
		self.title = XULocalizedString(self.title)
		
		self.contentView?.localizeView()
		
		if let toolbar = self.toolbar {
			for item in toolbar.items {
				item.label = XULocalizedString(item.label)
			}
		}
	}
	
}
