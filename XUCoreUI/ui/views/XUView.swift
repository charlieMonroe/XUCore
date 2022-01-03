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
	@IBInspectable public var backgroundColor: NSColor = .clear {
		didSet {
			self._updateLayer()
		}
	}
	
	/// Border color.
	@IBInspectable public var borderColor: NSColor = .clear {
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
	
	/// Masked corners in case of corner radius.
	public var maskedCorners: CACornerMask = [
		.layerMaxXMaxYCorner, .layerMinXMinYCorner,
		.layerMaxXMinYCorner, .layerMinXMaxYCorner
	]
	
	@objc private func _updateLayer() {
		self.wantsLayer = true
		
		if self.layer == nil {
			self.layer = CALayer()
		}
		
		self.layer!.backgroundColor = self.backgroundColor.cgColor
		self.layer!.borderColor = self.borderColor.cgColor
		self.layer!.borderWidth = CGFloat(self.borderWidth)
		self.layer!.cornerRadius = CGFloat(self.cornerRadius)
		
		if #available(macOS 10.13, *) {
			self.layer!.maskedCorners = self.maskedCorners
		}
	}
	
	open override func awakeFromNib() {
		super.awakeFromNib()
		
		self._updateLayer()
	}
	
	open override func updateLayer() {
		super.updateLayer()
		
		// This is generally done to support dynamic colors on
		// macOS 10.15 and later.		
		self._updateLayer()
	}
	
}
