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
public class XUBorderlessWindow: NSWindow {
	
	private func _innerInit() {
		NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(XUBorderlessWindow.updateBackground), name: NSWindowDidResizeNotification, object: self)
		NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(XUBorderlessWindow.updateBackground), name: NSWindowDidMoveNotification, object: self)
		
		self.collectionBehavior = .CanJoinAllSpaces
		self.hasShadow = true
		self.opaque = false
		self.updateBackground()
	}
	
	/// Override this method to customize the window content.
	public func drawRect(rect: CGRect) {
	}
	
	public override var canBecomeKeyWindow: Bool {
		return true
	}
	
	deinit {
		NSNotificationCenter.defaultCenter().removeObserver(self)
	}
	
	public override init(contentRect: CGRect, styleMask aStyle: Int, backing bufferingType: NSBackingStoreType, `defer` flag: Bool) {
		// Don't allow zero sizes;
		var frame = contentRect
		if frame.width < 1.0 || frame.height < 1.0 {
			// Little size, use arbitrary values
			frame.size.width = 200.0
			frame.size.height = 200.0
		}
		
		super.init(contentRect: frame, styleMask: NSBorderlessWindowMask, backing: NSBackingStoreType.Buffered, defer: flag)
		
		self._innerInit()
	}

	public required init?(coder: NSCoder) {
		super.init(coder: coder)
		
		self._innerInit()
	}
	
	/// Updates the background by redrawing. You should seldomly need to call
	/// this method directly.
	@objc public func updateBackground() {
		let windowSize = self.frame.size
		
		if isnan(windowSize.width) || isnan(windowSize.height) {
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
