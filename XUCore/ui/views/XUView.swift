//
//  XUView.swift
//  XUCore
//
//  Created by Charlie Monroe on 11/22/16.
//  Copyright © 2016 Charlie Monroe Software. All rights reserved.
//

import Cocoa

/// This is a simple NSView subclass that allows you to set the background and
/// border colors in Interface Builder.
@IBDesignable open class XUView: NSView {
	
	/// Background color.
	@IBInspectable var backgroundColor: NSColor = NSColor.clear
	
	/// Border color.
	@IBInspectable var borderColor: NSColor = NSColor.clear
	
	/// Border width.
	@IBInspectable var borderWidth: Double = 1.0
	
	
	open override func draw(_ dirtyRect: CGRect) {
		self.backgroundColor.setFill()
		self.borderColor.setStroke()
		
		let bPath = NSBezierPath(rect: self.bounds)
		bPath.lineWidth = CGFloat(self.borderWidth)
		bPath.fill()
		bPath.stroke()
	}
	
}
