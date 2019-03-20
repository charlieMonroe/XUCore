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
	@IBInspectable public var backgroundColor: NSColor = NSColor.clear {
		didSet {
			self._updateLayer()
		}
	}
	
	/// Border color.
	@IBInspectable public var borderColor: NSColor = NSColor.clear {
		didSet {
			self._updateLayer()
		}
	}
	
	/// Border width.
	@IBInspectable public var borderWidth: Double = 1.0 {
		didSet {
			self._updateLayer()
		}
	}
	
	/// Corner radius.
	@IBInspectable public var cornerRadius: Double = 0.0 {
		didSet {
			self._updateLayer()
		}
	}
	
	private func _updateLayer() {
		self.wantsLayer = true
		
		if self.layer == nil {
			self.layer = CALayer()
		}
		
		self.layer!.backgroundColor = self.backgroundColor.cgColor
		self.layer!.borderColor = self.borderColor.cgColor
		self.layer!.borderWidth = CGFloat(self.borderWidth)
		self.layer!.cornerRadius = CGFloat(self.cornerRadius)
	}
	
	open override func awakeFromNib() {
		super.awakeFromNib()
		
		self._updateLayer()
	}
	
//	open override func draw(_ dirtyRect: CGRect) {
//		self.backgroundColor.setFill()
//		self.borderColor.setStroke()
//
//		let bPath: NSBezierPath
//		if self.cornerRadius == 0.0 {
//			bPath = NSBezierPath(rect: self.bounds)
//		} else {
//			bPath = NSBezierPath(roundedRect: self.bounds, xRadius: CGFloat(self.cornerRadius), yRadius: CGFloat(self.cornerRadius))
//		}
//		bPath.lineWidth = CGFloat(self.borderWidth)
//		bPath.fill()
//		bPath.stroke()
//	}
	
}
