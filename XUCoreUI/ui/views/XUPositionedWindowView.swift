//
//  XUPositionedWindowView.swift
//  XUCore
//
//  Created by Charlie Monroe on 11/5/15.
//  Copyright © 2015 Charlie Monroe Software. All rights reserved.
//

import Cocoa
import XUCore

open class XUPositionedWindowView: NSView {

	@IBOutlet weak var connectedToWindow: NSWindow!

	open override func awakeFromNib() {
		if self.shouldBeConnectedOnAwakeFromNib {
			var superview = connectedToWindow.contentView?.superview
			if connectedToWindow.titlebarAccessoryViewControllers.count == 0 {
				/** Since 10.10.2, the titlebar view is deferred in creation.
				 * We need to force the creation by adding a blank titlebar accessory
				 * view controller.
				 */
				let controller = NSTitlebarAccessoryViewController()
				controller.layoutAttribute = .right
				controller.view = NSView()
				connectedToWindow.addTitlebarAccessoryViewController(controller)
			}

			superview = superview?.subviews.first(where: { (view) -> Bool in
				return view.isKind(of: NSClassFromString("NSTitlebarContainerView")!)
			})
			superview = superview?.subviews.first(where: { (view) -> Bool in
				return view.isKind(of: NSClassFromString("NSTitlebarView")!)
			})

			superview?.addSubview(self)
		}

		NotificationCenter.default.addObserver(self, selector: #selector(XUPositionedWindowView.updateFramePosition), name: NSWindow.didResizeNotification, object: connectedToWindow)

		self.postsFrameChangedNotifications = false

		self.updateFramePosition()
		self.localize()
	}

	deinit {
		NotificationCenter.default.removeObserver(self)
	}

	open override var frame: CGRect {
		get {
			if self.superview == nil {
				return super.frame
			}
			return self.frameForWindowBounds(self.superview!.bounds, andRealFrame: super.frame)
		}
		set(newValue) {
			super.frame = newValue
		}
	}


	/// Override this to NO if you don't want the view to be connected to the
	/// window on awakeFromNib under some cirtumstances. By default YES.
	open var shouldBeConnectedOnAwakeFromNib: Bool {
		return true
	}

	/// Override this to specify position of the view in window
	open func frameForWindowBounds(_ bounds: CGRect, andRealFrame realFrame: CGRect) -> CGRect {
		XUFatalError()
	}
	
	/// Updates frame position. Shouldn't be invoked manually.
	@objc open func updateFramePosition() {
		let rect = self.frame
		self.frame = rect
		self.autoresizingMask = .minXMargin
	}
}

open class XUTopCenterWindowView: XUPositionedWindowView {

	open override func frameForWindowBounds(_ bounds: CGRect, andRealFrame realFrame: CGRect) -> CGRect {
		var retRect = CGRect(x: (bounds.width - realFrame.width) / 2.0, y: bounds.height - realFrame.height, width: realFrame.width, height: realFrame.height)
		retRect = retRect.integral
		return retRect
	}
}

open class XUTopLeftWindowCornerView: XUPositionedWindowView {

	open override func frameForWindowBounds(_ bounds: CGRect, andRealFrame realFrame: CGRect) -> CGRect {
		let retRect = CGRect(x: 0.0, y: bounds.height - realFrame.height, width: realFrame.width, height: realFrame.height)
		return retRect
	}
}

open class XUTopRightWindowCornerView: XUPositionedWindowView {

	open override func frameForWindowBounds(_ bounds: CGRect, andRealFrame realFrame: CGRect) -> CGRect {
		var retRect = CGRect(x: bounds.width - realFrame.width - 5.0, y: bounds.height - realFrame.height, width: realFrame.width, height: realFrame.height)

		retRect = retRect.integral

		retRect.origin.y -= 1.0

		return retRect
	}
}

