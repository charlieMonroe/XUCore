//
//  XUMenuButton.swift
//  XUCore
//
//  Created by Charlie Monroe on 11/5/15.
//  Copyright © 2015 Charlie Monroe Software. All rights reserved.
//

import Cocoa

/// This is a button that displays self.menu on click as well as on rightMouseDown
/// - positioned correctly.
open class XUMenuButton: NSButton {

	@objc fileprivate func _displayMenu() {
		guard let menu = self.menu else {
			return
		}
		
		menu.popUp(positioning: nil, at: CGPoint(x: 0.0, y: self.bounds.height), in: self)
	}
	
	open override func awakeFromNib() {
		self.target = self
		self.action = #selector(XUMenuButton._displayMenu)
		
		self.menu?.localizeMenu()
		
		super.awakeFromNib()
	}
	open override func rightMouseDown(with event: NSEvent) {
		self._displayMenu()
	}
    
}
