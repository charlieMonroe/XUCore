//
//  XUPositionedWindowView.swift
//  XUCore
//
//  Created by Charlie Monroe on 11/5/15.
//  Copyright © 2015 Charlie Monroe Software. All rights reserved.
//

import Cocoa

public class XUPositionedWindowView: NSView {

	@IBOutlet weak var connectedToWindow: NSWindow!

	public override func awakeFromNib() {
		if self.shouldBeConnectedOnAwakeFromNib {
			var superview = connectedToWindow.contentView?.superview
			if connectedToWindow.titlebarAccessoryViewControllers.count == 0 {
				/** Since 10.10.2, the titlebar view is deferred in creation.
				 * We need to force the creation by adding a blank titlebar accessory
				 * view controller.
				 */
				let controller = NSTitlebarAccessoryViewController()
				controller.layoutAttribute = .Right
				controller.view = NSView()
				connectedToWindow.addTitlebarAccessoryViewController(controller)
			}

			superview = superview?.subviews.find({ (view) -> Bool in
				return view.isKindOfClass(NSClassFromString("NSTitlebarContainerView")!)
			})
			superview = superview?.subviews.find({ (view) -> Bool in
				return view.isKindOfClass(NSClassFromString("NSTitlebarView")!)
			})

			superview?.addSubview(self)
		}

		NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(XUPositionedWindowView.updateFramePosition), name: NSWindowDidResizeNotification, object: connectedToWindow)

		self.postsFrameChangedNotifications = false

		self.updateFramePosition()
		self.localizeView()
	}

	deinit {
		NSNotificationCenter.defaultCenter().removeObserver(self)
	}

	public override var frame: CGRect {
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

	/*
	 func layoutAttribute() -> NSLayoutAttribute {
	 return NSLayoutAttributeBottom

	 }
	 */

	/// Override this to NO if you don't want the view to be connected to the
	/// window on awakeFromNib under some cirtumstances. By default YES.
	public var shouldBeConnectedOnAwakeFromNib: Bool {
		return true
	}

	/// Override this to specify position of the view in window
	public func frameForWindowBounds(bounds: CGRect, andRealFrame realFrame: CGRect) -> CGRect {
		XUThrowAbstractException()
	}
	
	/// Updates frame position. Shouldn't be invoked manually.
	@objc public func updateFramePosition() {
		let rect = self.frame
		self.frame = rect
		self.autoresizingMask = .ViewMinXMargin
	}
}

public class XUTopCenterWindowView: XUPositionedWindowView {

	public override func frameForWindowBounds(bounds: CGRect, andRealFrame realFrame: CGRect) -> CGRect {
		var retRect = CGRect(x: (bounds.width - realFrame.width) / 2.0, y: bounds.height - realFrame.height, width: realFrame.width, height: realFrame.height)
		retRect = retRect.integral
		return retRect
	}
}

public class XUTopLeftWindowCornerView: XUPositionedWindowView {

	public override func frameForWindowBounds(bounds: CGRect, andRealFrame realFrame: CGRect) -> CGRect {
		let retRect = CGRect(x: 0.0, y: bounds.height - realFrame.height, width: realFrame.width, height: realFrame.height)
		return retRect
	}
}

public class XUTopRightWindowCornerView: XUPositionedWindowView {

	public override func frameForWindowBounds(bounds: CGRect, andRealFrame realFrame: CGRect) -> CGRect {
		var retRect = CGRect(x: bounds.width - realFrame.width - 5.0, y: bounds.height - realFrame.height, width: realFrame.width, height: realFrame.height)

		retRect = retRect.integral

		retRect.origin.y -= 1.0

		return retRect
	}
}

