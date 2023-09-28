//
//  NSWindow-NoodleEffects.swift
//  XUCore
//
//  Created by Charlie Monroe on 11/21/15.
//  Copyright © 2015 Charlie Monroe Software. All rights reserved.
//

import AppKit
import Foundation

/// Set this variable to a speed-up or slow down the effect
private let kXUZoomAnimationTimeMultiplier = 0.4


private class __XUZoomWindow: NSPanel {
	
	@objc override func animationResizeTime(_ newWindowFrame: CGRect) -> TimeInterval {
		return super.animationResizeTime(newWindowFrame) * kXUZoomAnimationTimeMultiplier
	}
	
}

public extension NSWindow {
	
	private static var __zoomWindow: NSWindow?
	
	/// Creates a new zoom window in screen rect. Nil is returned when there is
	/// no contentView, or the view fails to create the bitmap image representation.
	private func _createZoomWindowWithRect(_ rect: CGRect) -> NSPanel? {
		let frame = self.frame
		
		if self.windowNumber <= 0 {
			// Force window device. Kinda crufty but I don't see a visible flash
			// when doing this. May be a timing thing wrt the vertical refresh.
			self.orderBack(self)
			self.orderOut(self)
		}
		
		let image = NSImage(size: frame.size)
		
		guard let view = self.contentView?.superview else {
			return nil
		}
		guard let imageRep = view.bitmapImageRepForCachingDisplay(in: view.bounds) else {
			return nil
		}
		
		view.cacheDisplay(in: view.bounds, to: imageRep)
		image.addRepresentation(imageRep)
		
		let mask = NSWindow.StyleMask.borderless		
		let zoomWindow = __XUZoomWindow(contentRect: rect, styleMask: mask, backing: .buffered, defer: false)
		zoomWindow.backgroundColor = NSColor(deviceWhite: 0.0, alpha: 0.0)
		zoomWindow.hasShadow = self.hasShadow
		zoomWindow.level = .modalPanel
		zoomWindow.isOpaque = false
		
		let imageView = NSImageView(frame: zoomWindow.contentRect(forFrameRect: frame))
		imageView.image = image
		imageView.imageFrameStyle = .none
		imageView.imageScaling = .scaleAxesIndependently
		imageView.autoresizingMask = [.width, .height]
		zoomWindow.contentView = imageView
		
		NSWindow.__zoomWindow = zoomWindow
		
		return zoomWindow
	}
	
	/// Pops the window on screen from startRect.
	func zoomIn(fromRect startRect: CGRect) {
		if self.isVisible {
			return // Do nothing if we're already on-screen
		}
		
		let frame = self.frame
		self.setFrame(frame, display: true)
		
		let zoomWindow = self._createZoomWindowWithRect(startRect)
		zoomWindow?.orderFront(self)
		zoomWindow?.setFrame(frame, display: true, animate: true)
		
		self.orderFront(nil)
		
		zoomWindow?.close()
		NSWindow.__zoomWindow = nil
	}
	
	/// Removes the window from screen by zooming off to the center of the window.
	func popAway() {
		var frame = self.frame
		frame.origin.x += (frame.width / 2.0) - 10.0
		frame.origin.y += (frame.height / 2.0) - 10.0
		frame.size.width = 20.0
		frame.size.height = 20.0
		
		self.zoomOut(toRect: frame)
	}
	
	/// Pops the window on screen from the middle of self.frame.
	func pop() {
		self.display()
		
		let frame = self.frame
		if self.isVisible {
			return // Already visible
		}
		
		let originalFrame = frame
		var enlargedFrame = originalFrame
		enlargedFrame.origin.x -= 12.5
		enlargedFrame.origin.y -= 12.5
		enlargedFrame.size.width += 25.0
		enlargedFrame.size.height += 25.0
		
		var fromRect = originalFrame
		fromRect.origin.x += originalFrame.width / 2.0
		fromRect.origin.y += originalFrame.height / 2.0
		fromRect.size.width = 1.0
		fromRect.size.height = 1.0
		
		let zoomWindow = self._createZoomWindowWithRect(fromRect)
		zoomWindow?.orderFront(self)
		zoomWindow?.setFrame(enlargedFrame, display: true, animate: true)
		zoomWindow?.setFrame(originalFrame, display: true, animate: true)
		
		self.makeKeyAndOrderFront(self)
		
		zoomWindow?.close()
		
		NSWindow.__zoomWindow = nil
	}
	
	/// Removes the window from screen by zooming off to endRect.
	func zoomOut(toRect endRect: CGRect) {
		if !self.isVisible {
			return // Already off screen
		}
		
		let frame = self.frame
		
		let zoomWindow = self._createZoomWindowWithRect(frame)
		zoomWindow?.orderFront(self)
		
		self.orderOut(self)
		
		zoomWindow?.setFrame(endRect, display: true, animate: true)
		zoomWindow?.close()
		
		NSWindow.__zoomWindow = nil
	}
	
}


