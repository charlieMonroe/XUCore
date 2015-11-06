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
public class XUMenuButton: NSButton {

	@objc private func _displayMenu() {
		guard let menu = self.menu else {
			return
		}
		
		menu.popUpMenuPositioningItem(nil, atLocation: CGPointMake(0.0, self.bounds.size.height), inView: self)
	}
	
	public override func awakeFromNib() {
		self.target = self
		self.action = "_displayMenu"
		
		self.menu?.localizeMenu()
		
		super.awakeFromNib()
	}
	public override func rightMouseDown(event: NSEvent) {
		self._displayMenu()
	}
    
}

/// This is a deprecated class for detecting use of deprecated FCMenuButton
@objc(FCMenuButton) public class FCMenuButton: XUMenuButton {
	
	public override func awakeFromNib() {
		FCLog("WARNING: Deprecated use of \(self.dynamicType) - use XUCore.\(self.superclass!) instead")
		
		super.awakeFromNib()
	}
	
}
