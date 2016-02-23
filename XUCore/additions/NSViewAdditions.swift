//
//  NSViewAdditions.swift
//  XUCore
//
//  Created by Charlie Monroe on 11/8/15.
//  Copyright © 2015 Charlie Monroe Software. All rights reserved.
//

import Foundation

public extension NSView {
	
	/// Sets enabled on subviews.
	public func setDeepEnabled(flag: Bool) {
		for view in self.subviews {
			if let control = view as? NSControl {
				control.enabled = flag
			}else{
				view.setDeepEnabled(flag)
			}
		}
	}
	
	public var screenCoordinatesOfSelf: CGRect {
		return self.screenCoordinatesOfFrame(self.bounds)
	}
	public func screenCoordinatesOfFrame(frame: CGRect) -> CGRect {
		if self.window == nil {
			return CGRectZero
		}
		
		var rect = self.convertRect(frame, toView: nil)
		let windowFrame = self.window!.frame
		rect.origin.x += windowFrame.origin.x
		rect.origin.y += windowFrame.origin.y
		return rect
	}
	public func screenCoordinatesOfPoint(point: CGPoint) -> CGPoint {
		if self.window == nil {
			return CGPoint()
		}
		
		var localPoint = self.convertPoint(point, toView: nil)
		let windowFrame = self.window!.frame
		localPoint.x += windowFrame.origin.x
		localPoint.y += windowFrame.origin.y
		return localPoint
	}
	
	
}
