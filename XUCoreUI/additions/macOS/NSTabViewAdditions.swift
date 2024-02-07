//
//  NSTabViewAdditions.swift
//  XUCore
//
//  Created by Charlie Monroe on 11/8/15.
//  Copyright © 2015 Charlie Monroe Software. All rights reserved.
//

import AppKit
import Foundation

public extension NSTabView {
	
	/// Sets .enabled on all subviews as `flag`
	override func setDeepEnabled(_ flag: Bool) {
		for item in self.tabViewItems {
			item.view?.setDeepEnabled(flag)
		}
	}
	
}

