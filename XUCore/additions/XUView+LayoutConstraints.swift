//
//  XUView+LayoutConstraints.swift
//  XUCore
//
//  Created by Charlie Monroe on 6/2/17.
//  Copyright © 2017 Charlie Monroe Software. All rights reserved.
//

import Foundation

/// __XUBridgedView is either NSView or UIView.
public extension __XUBridgedView {
	
	/// Adds constraints that make `view` centered horizontally and vertically
	/// in self. The `view` must already be a subview of self. Returns the 
	/// created constraints if needed.
	@discardableResult
	public func addConstraints(centeringView view: __XUBridgedView) -> (horizontal: NSLayoutConstraint, vertical: NSLayoutConstraint) {
		let horizontal = NSLayoutConstraint(item: view, attribute: .centerX, relatedBy: .equal, toItem: self, attribute: .centerX, multiplier: 1.0, constant: 0.0)
		let vertical = NSLayoutConstraint(item: view, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1.0, constant: 0.0)
		self.addConstraints([horizontal, vertical])
		return (horizontal, vertical)
	}
	
	/// Pins the view to leading, trailing, top and bottom in self. You can
	/// optionally specify padding.
	@discardableResult
	public func addConstraints(pinningViewOnAllSides view: __XUBridgedView, leftPadding: CGFloat = 0.0, rightPadding: CGFloat = 0.0, topPadding: CGFloat = 0.0, bottomPadding: CGFloat = 0.0) -> [NSLayoutConstraint] {
		return self.addConstraints(pinningViewHorizontally: view, leftPadding: leftPadding, rightPadding: rightPadding)
				+ self.addConstraints(pinningViewVertically: view, topPadding: topPadding, bottomPadding: bottomPadding)
	}
	
	/// Pins the view to leading and trailing in self. You can optionally specify
	/// left and right padding. Visually, this is |-leftPadding-[view]-rightPadding-|.
	@discardableResult
	public func addConstraints(pinningViewHorizontally view: __XUBridgedView, leftPadding: CGFloat = 0.0, rightPadding: CGFloat = 0.0) -> [NSLayoutConstraint] {
		let format = "|-leftPadding-[view]-rightPadding-|"
		let constraints = NSLayoutConstraint.constraints(withVisualFormat: format, options: [.alignAllLeading, .alignAllTrailing], metrics: [
			"leftPadding": leftPadding as NSNumber,
			"rightPadding": rightPadding as NSNumber
		], views: ["view": view])
		self.addConstraints(constraints)
		return constraints
	}
	
	/// Pins the view to top and bottom in self. You can optionally specify
	/// top and bottom padding. Visually, this is V:|-topPadding-[view]-bottomPadding-|.
	@discardableResult
	public func addConstraints(pinningViewVertically view: __XUBridgedView, topPadding: CGFloat = 0.0, bottomPadding: CGFloat = 0.0) -> [NSLayoutConstraint] {
		let format = "V:|-topPadding-[view]-bottomPadding-|"
		let constraints = NSLayoutConstraint.constraints(withVisualFormat: format, options: [.alignAllLeading, .alignAllTrailing], metrics: [
			"topPadding": topPadding as NSNumber,
			"bottomPadding": bottomPadding as NSNumber
		], views: ["view": view])
		self.addConstraints(constraints)
		return constraints
	}
	
}