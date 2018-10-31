//
//  NSViewAdditions.swift
//  XUCore
//
//  Created by Charlie Monroe on 11/8/15.
//  Copyright © 2015 Charlie Monroe Software. All rights reserved.
//

import Foundation

public extension NSView {
	
	private func _enclosingView<T: NSView>() -> T? {
		var view: NSView? = self
		while view != nil {
			if let targetView = view as? T {
				return targetView
			}
			
			view = view!.superview
		}
		return nil
	}
		
	/// Returns enclosing table row view or nil.
	public var enclosingTableRowView: NSTableRowView? {
		return self._enclosingView()
	}
	
	/// Returns enclosing table view or nil.
	public var enclosingTableView: NSTableView? {
		return self._enclosingView()
	}
	
	public func enclosingView<T: NSView>(ofType type: T.Type) -> T? {
		return self._enclosingView()
	}
	
	/// Sets enabled on subviews.
	@objc public func setDeepEnabled(_ flag: Bool) {
		for view in self.subviews {
			if let control = view as? NSControl {
				control.isEnabled = flag
			}else{
				view.setDeepEnabled(flag)
			}
		}
	}
	
	/// Returns screen coordinates of the view. Note that it will return an empty
	/// rect if the view is not attached to a window.
	public var screenCoordinates: CGRect {
		return self.screenCoordinates(ofRect: self.bounds)
	}
	
	/// Returns screen coordinates of the rect inside this view. Note that it will
	/// return an empty rect if the view is not attached to a window.
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
	
	/// Returns screen coordinates of the point inside this view. Note that it will
	/// return an empty point if the view is not attached to a window.
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
