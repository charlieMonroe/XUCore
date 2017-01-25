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
public final class XUEventIgnoringButton: NSButton {
	
	public override func acceptsFirstMouse(for theEvent: NSEvent?) -> Bool {
		return false
	}
	public override var acceptsFirstResponder: Bool {
		return false
	}
	public override func mouseDown(with theEvent: NSEvent) {
		// No-op
	}
	
}
