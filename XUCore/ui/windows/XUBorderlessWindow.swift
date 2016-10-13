//
// XUBorderlessWindow.swift
// XUCore
//
// Created by Charlie Monroe on 1/3/16.
// Copyright © 2016 Charlie Monroe Software. All rights reserved.
//

import Foundation

/// This is a window that allows being updated like a NSView - just override
// / -drawRect:.
open class XUBorderlessWindow: NSWindow {
	
	fileprivate func _innerInit() {
		NotificationCenter.default.addObserver(self, selector: #selector(XUBorderlessWindow.updateBackground), name: NSNotification.Name.NSWindowDidResize, object: self)
		NotificationCenter.default.addObserver(self, selector: #selector(XUBorderlessWindow.updateBackground), name: NSNotification.Name.NSWindowDidMove, object: self)
		
		self.collectionBehavior = .canJoinAllSpaces
		self.hasShadow = true
		self.isOpaque = false
		self.updateBackground()
	}
	
	/// Override this method to customize the window content.
	open func drawRect(_ rect: CGRect) {
	}
	
	open override var canBecomeKey: Bool {
		return true
	}
	
	deinit {
		NotificationCenter.default.removeObserver(self)
	}
	
	public override init(contentRect: CGRect, styleMask aStyle: NSWindowStyleMask, backing bufferingType: NSBackingStoreType, defer flag: Bool) {
		// Don't allow zero sizes;
		var frame = contentRect
		if frame.width < 1.0 || frame.height < 1.0 {
			// Little size, use arbitrary values
			frame.size.width = 200.0
			frame.size.height = 200.0
		}
		
		var style = aStyle
		style.insert(.borderless)
		
		super.init(contentRect: frame, styleMask: style, backing: NSBackingStoreType.buffered, defer: flag)
		
		self._innerInit()
	}

	/// Updates the background by redrawing. You should seldomly need to call
	/// this method directly.
	@objc open func updateBackground() {
		let windowSize = self.frame.size
		
		if windowSize.width.isNaN || windowSize.height.isNaN {
			return
		}
		
		if windowSize == CGSize() {
			// Zero size -> return;
			return
		}
		
		let backgroundImage = NSImage(size: windowSize)
		backgroundImage.lockFocus()
		
		// Draw rect
		var bounds = self.frame
		
		bounds.origin = CGPoint()
		
		self.drawRect(bounds)
		
		backgroundImage.unlockFocus()
		
		self.backgroundColor = NSColor(patternImage: backgroundImage)
	}
	
}
