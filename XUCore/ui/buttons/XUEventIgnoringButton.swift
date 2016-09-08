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
open class XUEventIgnoringButton: NSButton {
	
	open override func acceptsFirstMouse(for theEvent: NSEvent?) -> Bool {
		return false
	}
	open override var acceptsFirstResponder: Bool {
		return false
	}
	open override func mouseDown(with theEvent: NSEvent) {
		// No-op
	}
	
}
