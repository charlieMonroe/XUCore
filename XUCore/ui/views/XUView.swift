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
	@IBInspectable public var backgroundColor: NSColor = NSColor.clear
	
	/// Border color.
	@IBInspectable public var borderColor: NSColor = NSColor.clear
	
	/// Border width.
	@IBInspectable public var borderWidth: Double = 1.0
	
	/// Corner radius.
	@IBInspectable public var cornerRadius: Double = 0.0
	
	
	open override func draw(_ dirtyRect: CGRect) {
		self.backgroundColor.setFill()
		self.borderColor.setStroke()
		
		let bPath: NSBezierPath
		if self.cornerRadius == 0.0 {
			bPath = NSBezierPath(rect: self.bounds)
		} else {
			bPath = NSBezierPath(roundedRect: self.bounds, xRadius: CGFloat(self.cornerRadius), yRadius: CGFloat(self.cornerRadius))
		}
		bPath.lineWidth = CGFloat(self.borderWidth)
		bPath.fill()
		bPath.stroke()
	}
	
}
