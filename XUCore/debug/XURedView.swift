//
//  XURedView.swift
//  XUCore
//
//  Created by Charlie Monroe on 11/11/15.
//  Copyright © 2015 Charlie Monroe Software. All rights reserved.
//

import Cocoa

/// Debugging view that is painted red, which allows you to easily see the view
/// boundaries.
public final class XURedView: NSView {
	
	public override func draw(_ dirtyRect: CGRect) {
		NSColor.red.set()
		NSRectFill(dirtyRect)
	}
	public override var isFlipped: Bool {
		return true
	}
	
}

