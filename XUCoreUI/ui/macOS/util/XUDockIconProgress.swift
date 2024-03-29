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

	private static let barHeight: CGFloat = 20.0

	private var _lastUpdated: Double = 0.0

	public static let shared: XUDockIconProgress = XUDockIconProgress()
	
	/// Override this in order to have createProgressImage() called
	/// even in case there is no progress to display.
	open var providesCustomIconEvenWithNoProgress: Bool {
		return false
	}
	
	/// Create an image for the Dock icon. It should include the application icon.
	open func createProgressImage() -> NSImage {
		let im: NSImage = NSImage(named: NSImage.applicationIconName)!.copy() as! NSImage
		im.size = CGSize(width: 128.0, height: 128.0)
		
		let barRect = self.progressBarFrame

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
	
	/// Frame of the progress bar within the image. The image is always 128.0 x 128.0
	/// in size.
	open var progressBarFrame: CGRect {
		return CGRect(x: 0.0, y: 25.0, width: 128.0, height: XUDockIconProgress.barHeight)
	}

	public var progressValue: Double = 0.0 {
		didSet {
			let needsVisualUpdate = abs(Double(_lastUpdated - progressValue)) > 0.01 || _lastUpdated == 0.0
			if needsVisualUpdate {
				_lastUpdated = progressValue
				self.updateDockIcon()
			}
		}
	}
	
	
	/// Updates the Dock icon. You should not override this method.
	public func updateDockIcon() {
		if !Thread.isMainThread {
			DispatchQueue.main.async(execute: {
				self.updateDockIcon()
			})
			return
		}
		
		let progress = self.progressValue
		
		
		if self.providesCustomIconEvenWithNoProgress || (progress > 0.0 && progress < 1.0) {
			let image = self.createProgressImage()
			NSApplication.shared.applicationIconImage = image
		} else {
			NSApplication.shared.applicationIconImage = nil
		}
	}

	public init() {
		
	}
}
