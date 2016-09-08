//
//  XUMenuItem.swift
//  XUCore
//
//  Created by Charlie Monroe on 9/7/16.
//  Copyright © 2016 Charlie Monroe Software. All rights reserved.
//

import Cocoa

/// This is a specialized menu item subclass that allows using closures for handling
/// menu item actions.
public final class XUMenuItem: NSMenuItem {
	
	/// Action handler.
	public let actionHandler: ((XUMenuItem) -> Void)?
	
	@objc fileprivate func _actionHandler(_ sender: XUMenuItem) {
		self.actionHandler?(sender)
	}
	
	/// Designated initializer.
	public init(title: String, andActionHandler actionHandler: ((XUMenuItem) -> Void)? = nil) {
		self.actionHandler = actionHandler
		super.init(title: title, action: #selector(_actionHandler(_:)), keyEquivalent: "")
		self.target = self
	}
	
	public required init(coder aDecoder: NSCoder) {
		self.actionHandler = nil
		super.init(coder: aDecoder)
	}
	
}
