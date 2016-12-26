//
//  XUDockIconProgress.swift
//  Downie
//
//  Created by Charlie Monroe on 5/11/15.
//  Copyright (c) 2015 Charlie Monroe Software. All rights reserved.
//

import AppKit

/// This class represents the Dock icon's progress bar.
open class XUDockIconProgress {

	fileprivate let kXUDockProgressBarHeight: CGFloat = 20.0
	fileprivate let kXUDockProgressBarInsideHeight = (20.0 - 2.0)

	fileprivate var _lastUpdated: Double = 0.0

	open static let shared: XUDockIconProgress = XUDockIconProgress()
	
	fileprivate func _createProgressImage() -> NSImage {
		let im: NSImage = NSImage(named: NSImageNameApplicationIcon)!.copy() as! NSImage
		let barRect = CGRect(x: 0.0, y: 25.0, width: 128.0, height: kXUDockProgressBarHeight)

		var progress = self.progressValue
		if progress < 0.1 {
			progress = 0.1
		}

		im.lockFocus()

		var bounds = barRect
		var bezierPath = NSBezierPath(roundedRect: bounds, xRadius: bounds.height / 2.0, yRadius: bounds.height / 2.0)
		NSColor.white.set()
		bezierPath.fill()

		bounds = bounds.insetBy(dx: 2.0, dy: 2.0)
		bezierPath = NSBezierPath(roundedRect: bounds, xRadius: bounds.height / 2.0, yRadius: bounds.height / 2.0)
		NSColor.black.set()
		bezierPath.fill()

		bounds = bounds.insetBy(dx: 2.0, dy: 2.0)
		bounds.size.width = bounds.width * CGFloat(progress)
		bezierPath = NSBezierPath(roundedRect: bounds, xRadius: bounds.height / 2.0, yRadius: bounds.height / 2.0)
		NSColor.white.set()
		bezierPath.fill()

		im.unlockFocus()
		return im
	}

	fileprivate func _updateDockIcon() -> Void {
		if !Thread.isMainThread {
			DispatchQueue.main.async(execute: {
				self._updateDockIcon()
			})
			return
		}

		let progress = self.progressValue
		
		
		if progress > 0.0 && progress < 1.0 {
			let image = self._createProgressImage()
			NSApplication.shared().applicationIconImage = image
		} else {
			NSApplication.shared().applicationIconImage = nil
		}
	}

	open var progressValue: Double = 0.0 {
		didSet {
			let needsVisualUpdate = abs(Double(_lastUpdated - progressValue)) > 0.01 || _lastUpdated == 0.0
			if needsVisualUpdate {
				_lastUpdated = progressValue
				self._updateDockIcon()
			}
		}
	}

	public init() {
		
	}
}
