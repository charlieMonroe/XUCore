//
//  XUDockIconProgress.swift
//  Downie
//
//  Created by Charlie Monroe on 5/11/15.
//  Copyright (c) 2015 Charlie Monroe Software. All rights reserved.
//

import AppKit

/// This class represents the Dock icon's progress bar.
public class XUDockIconProgress: NSObject {
		
	private let kXUDockProgressBarHeight : CGFloat = 20.0
	private let kXUDockProgressBarInsideHeight = (20.0 - 2.0)
	
	private var _lastUpdated : Double = 0.0
	
	public static let sharedProgress: XUDockIconProgress = XUDockIconProgress()
	
	private func _progressImage() -> NSImage {
		let im: NSImage = NSImage(named: "NSApplicationIcon")?.copy() as! NSImage
		let barRect = CGRect(x: 0.0, y: 25.0, width: 128.0, height: kXUDockProgressBarHeight)
		
		var progress = self.progressValue
		if (progress < 0.1){
			progress = 0.1
		}
		
		im.lockFocus()
		
		var bounds = barRect
		var bezierPath = NSBezierPath(roundedRect: bounds, xRadius: bounds.size.height / 2.0, yRadius: bounds.size.height / 2.0)
		NSColor.whiteColor().set()
		bezierPath.fill()
		
		bounds = CGRectInset(bounds, 2.0, 2.0)
		bezierPath = NSBezierPath(roundedRect: bounds, xRadius: bounds.size.height / 2.0, yRadius: bounds.size.height / 2.0)
		NSColor.blackColor().set()
		bezierPath.fill()
		
		bounds = CGRectInset(bounds, 2.0, 2.0)
		bounds.size.width = bounds.size.width * CGFloat(progress)
		bezierPath = NSBezierPath(roundedRect: bounds, xRadius: bounds.size.height / 2.0, yRadius: bounds.size.height / 2.0)
		NSColor.whiteColor().set()
		bezierPath.fill()
		
		im.unlockFocus()
		return im
	}
	
	private func _updateDockIcon() -> Void {
		if (!NSThread.isMainThread()){
			dispatch_async(dispatch_get_main_queue(),{
				self._updateDockIcon()
			})
			return;
		}
		
		let progress = self.progressValue
		if (progress > 0.0 && progress < 1.0){
			let image = self._progressImage()
			NSApplication.sharedApplication().applicationIconImage = image
		}else{
			NSApplication.sharedApplication().applicationIconImage = nil
		}
	}
	
	public var progressValue : Double = 0.0 {
		didSet {
			let needsVisualUpdate = abs(Double(_lastUpdated - progressValue)) > 0.001 || _lastUpdated == 0.0;
			if (needsVisualUpdate){
				_lastUpdated = progressValue
				self._updateDockIcon()
			}
		}
	}
	
	public override init() {
		super.init()
	}
}
