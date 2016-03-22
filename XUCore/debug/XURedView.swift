//
//  XURedView.swift
//  XUCore
//
//  Created by Charlie Monroe on 11/11/15.
//  Copyright © 2015 Charlie Monroe Software. All rights reserved.
//

import Foundation

/// Debugging view that is painted red, which allows you to easily see the view
/// boundaries.
public class XURedView: NSView {
	
	public override func drawRect(dirtyRect: CGRect) {
		NSColor.redColor().set()
		NSRectFill(dirtyRect)
	}
	public override var flipped: Bool {
		return true
	}
	
}

