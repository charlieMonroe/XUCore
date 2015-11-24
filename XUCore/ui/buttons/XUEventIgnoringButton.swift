//
//  XUEventIgnoringButton.swift
//  XUCore
//
//  Created by Charlie Monroe on 11/24/15.
//  Copyright © 2015 Charlie Monroe Software. All rights reserved.
//

import Cocoa

/// This is a button that does literally nothing. It is used for padding between
/// buttons of the same appearance.
public class XUEventIgnoringButton: NSButton {
	
	public override func acceptsFirstMouse(theEvent: NSEvent?) -> Bool {
		return false
	}
	public override var acceptsFirstResponder: Bool {
		return false
	}
	public override func mouseDown(theEvent: NSEvent) {
		// No-op
	}
	
}


@available(*, deprecated)
@objc(FCEventIgnoringButton) class FCEventIgnoringButton: XUEventIgnoringButton {
	
	override func awakeFromNib() {
		XULog("WARNING: Deprecated use of \(self.dynamicType) - use XUCore.\(self.superclass!) instead")
		
		super.awakeFromNib()
	}
	
}