//
//  NSWindowLocalizationSupport.swift
//  XUCore
//
//  Created by Charlie Monroe on 11/7/15.
//  Copyright © 2015 Charlie Monroe Software. All rights reserved.
//

import AppKit
import Foundation
import XUCore

extension NSWindow: XULocalizableUIElement {
	
	public func localize(from bundle: Bundle = Bundle.main) {
		self.title = Localized(self.title, in: bundle)
		
		self.contentView?.localize(from: bundle)
		
		if let toolbar = self.toolbar {
			for item in toolbar.items {
				item.label = Localized(item.label, in: bundle)
			}
		}
	}

}
