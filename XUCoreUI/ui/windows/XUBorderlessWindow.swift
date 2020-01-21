//
// XUBorderlessWindow.swift
// XUCore
//
// Created by Charlie Monroe on 1/3/16.
// Copyright © 2016 Charlie Monroe Software. All rights reserved.
//

import AppKit

/// This is a window that allows being updated like a NSView - just override
// / -drawRect:.
open class XUBorderlessWindow: NSWindow {
	
	private var _cachedImageSize: CGSize = .zero
	
	private func _innerInit() {
		NotificationCenter.default.addObserver(self, selector: #selector(XUBorderlessWindow.updateBackground), name: NSWindow.didResizeNotification, object: self)
		NotificationCenter.default.addObserver(self, selector: #selector(XUBorderlessWindow.updateBackground), name: NSWindow.didMoveNotification, object: self)
		
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
	
	/// If this returns true then if the window resizes, the background may be kept.
	/// If the window resizes too much, then the background is discarded to lower
	/// memory footprint. It also allows for some optimizations like requesting
	/// larger background image so that during the live resize, the redrawing
	/// doesn't occurr that often.
	open var canCropBackgroundImage: Bool {
		return false
	}
	
	deinit {
		NotificationCenter.default.removeObserver(self)
	}
	
	public override init(contentRect: CGRect, styleMask aStyle: NSWindow.StyleMask, backing bufferingType: NSWindow.BackingStoreType, defer flag: Bool) {
		// Don't allow zero sizes;
		var frame = contentRect
		if frame.width < 1.0 || frame.height < 1.0 {
			// Little size, use arbitrary values
			frame.size.width = 200.0
			frame.size.height = 200.0
		}
		
		var style = aStyle
		style.insert(.borderless)
		
		super.init(contentRect: frame, styleMask: style, backing: .buffered, defer: flag)
		
		self._innerInit()
	}

	/// Updates the background by redrawing. You should seldomly need to call
	/// this method directly.
	@objc open func updateBackground() {
		var windowSize = self.frame.size
		if windowSize.width.isNaN || windowSize.height.isNaN {
			return
		}
		
		if windowSize == .zero || windowSize == _cachedImageSize {
			// Zero size -> return;
			return
		}
		
		if self.canCropBackgroundImage {
			if windowSize.width <= _cachedImageSize.width, windowSize.height <= _cachedImageSize.height {
				// We can just crop it. If there is a significant size difference,
				// however (75%), we will redraw.
				if windowSize.area / _cachedImageSize.area > 0.75 {
					// It's fine, let's leave it.
					return
				}
				
				// We need to redraw, we're becoming too small.
				
			} else {
				// The window is larger. Let's increase the size of the window
				// so that we can leverage the fact it's croppable.
				windowSize += CGSize(width: 300.0, height: 300.0)
			}
		}
		
		_cachedImageSize = windowSize
		
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
