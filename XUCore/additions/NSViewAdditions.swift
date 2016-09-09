//
//  NSViewAdditions.swift
//  XUCore
//
//  Created by Charlie Monroe on 11/8/15.
//  Copyright © 2015 Charlie Monroe Software. All rights reserved.
//

import Foundation

public extension NSView {
	
	public var enclosingTableView: NSTableView? {
		var view: NSView? = self.superview
		while view != nil {
			if let tableView = view as? NSTableView {
				return tableView
			}
			
			view = view?.superview
		}
		
		return nil
	}
	
	/// Sets enabled on subviews.
	public func setDeepEnabled(_ flag: Bool) {
		for view in self.subviews {
			if let control = view as? NSControl {
				control.isEnabled = flag
			}else{
				view.setDeepEnabled(flag)
			}
		}
	}
	
	@available(*, deprecated, renamed: "screenCoordinates")
	public var screenCoordinatesOfSelf: CGRect {
		return self.screenCoordinates
	}
	
	public var screenCoordinates: CGRect {
		return self.screenCoordinates(ofRect: self.bounds)
	}
	
	public func screenCoordinates(ofRect frame: CGRect) -> CGRect {
		if self.window == nil {
			return CGRect()
		}
		
		var rect = self.convert(frame, to: nil)
		let windowFrame = self.window!.frame
		rect.origin.x += windowFrame.minX
		rect.origin.y += windowFrame.minY
		return rect
	}
	
	public func screenCoordinates(ofPoint point: CGPoint) -> CGPoint {
		if self.window == nil {
			return CGPoint()
		}
		
		var localPoint = self.convert(point, to: nil)
		let windowFrame = self.window!.frame
		localPoint.x += windowFrame.minX
		localPoint.y += windowFrame.minY
		return localPoint
	}
	
	
}
