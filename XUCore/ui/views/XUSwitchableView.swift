//
//  XUSwitchableView.swift
//  XUCore
//
//  Created by Charlie Monroe on 11/6/15.
//  Copyright © 2015 Charlie Monroe Software. All rights reserved.
//

import Cocoa

/// This is a view that manages switching between screens. An example usage is
/// in a tutorial, where you slide one screen after another.
public class XUSwitchableView: NSView {
	
	private var _isAnimating: Bool = false
	private var _otherView: NSView?
	
	
	@objc private func _frameChanged(_ sender: AnyObject?) {
		//! NSEqualRects([self bounds], [[self superview] bounds])
		if _isAnimating {
			return
		}
		
		self.currentView?.frame = self.bounds
		if _otherView != nil && !_otherView!.isHidden {
			_otherView?.isHidden = true
		}
	}
	
	@objc private func _unsetAnimation(_ sender: AnyObject?) {
		_isAnimating = false
		
		//Remove the previous cached view
		_otherView?.removeFromSuperview()
		_otherView = nil
		
		self.currentView?.frame = self.bounds
	}
	
	/// Current view displayed.
	public var currentView: NSView? {
		didSet (oldView) {
			if oldView == nil && self.currentView != nil {
				self.currentView?.frame = self.bounds
				self.addSubview(self.currentView!)
			}
		}
	}
	deinit {
		NotificationCenter.default.removeObserver(self)
	}
	public override init(frame: CGRect) {
		super.init(frame: frame)
		
		self.postsFrameChangedNotifications = true
		NotificationCenter.default.addObserver(self, selector: #selector(XUSwitchableView._frameChanged(_:)), name: NSView.frameDidChangeNotification, object: self)
	}
	public required init?(coder: NSCoder) {
		super.init(coder: coder)
		
		self.postsFrameChangedNotifications = true
		NotificationCenter.default.addObserver(self, selector: #selector(XUSwitchableView._frameChanged(_:)), name: NSView.frameDidChangeNotification, object: self)
	}
	
	public override var isFlipped: Bool {
		return true
	}
	public override var mouseDownCanMoveWindow: Bool {
		return true
	}
	
	/// Switches to a new view in direction specified and if adjustWindow is true,
	/// the window size is adjusted as well.
	public func switchToView(_ view: NSView, inDirection direction: XUDirection, adjustWindow: Bool = false) {
		_isAnimating = true
		
		// Make sure the view isn't hidden
		if _otherView != nil && _otherView!.isHidden {
			_otherView!.isHidden = false
		}
		
		if self.currentView == nil {
			// There is currently no view, so just add the new one, no animation
			self.addSubview(view)
			
			view.frame = self.bounds
			self.currentView = view
			return
		}
		
		if self.currentView == view {
			// It's the same view, do nothing
			return
		}
		
		// NSAnimationContext.currentContext().duration = 3.0
		NSAnimationContext.beginGrouping()
		
		// [[NSAnimationContext currentContext] setDuration:3.0];
		
		let newViewSize = view.bounds.size
		let oldViewSize = self.currentView!.bounds.size
		if adjustWindow {
			// Adjust the window - this is based on deltas
			var newFrame = self.window!.frame
			var delta = (newViewSize.width - oldViewSize.width)
			newFrame.size.width += delta
			newFrame.origin.x -= delta / 2.0
			
			// Keeping it centered
			// Height delta
			delta = (newViewSize.height - oldViewSize.height)
			newFrame.size.height += delta
			newFrame.origin.y -= delta
			
			// Keeping the top aligned
			self.window!.animator().setFrame(newFrame, display: true)
		}
		
		let r = self.bounds
		let targetSize = adjustWindow ? newViewSize : r.size
		let newViewRect: CGRect
		
		// The rect in which the new view should be placed (it's offscreen)
		let toBeMoved: CGRect
		
		// The rect where the current view should move out to make place for the new view
		switch direction {
			case .leftToRight:
				// From left to right
				newViewRect = CGRect(x: oldViewSize.width, y: 0.0, width: targetSize.width, height: targetSize.height)
				toBeMoved = CGRect(x: -oldViewSize.width, y: 0.0, width: oldViewSize.width, height: oldViewSize.height)
			case .rightToLeft:
				// From right to left
				newViewRect = CGRect(x: -newViewSize.width, y: 0.0, width: newViewSize.width, height: newViewSize.height)
				toBeMoved = CGRect(x: oldViewSize.width, y: 0.0, width: oldViewSize.width, height: oldViewSize.height)
			case .topToBottom:
				// From up to down
				newViewRect = CGRect(x: 0, y: r.height, width: r.width, height: r.height)
				toBeMoved = CGRect(x: 0, y: -r.height, width: r.width, height: r.height)
			case .bottomToTop:
				// FCTop - from down to up
				newViewRect = CGRect(x: 0, y: -r.height, width: r.width, height: r.height)
				toBeMoved = CGRect(x: 0, y: r.height, width: r.width, height: r.height)
		}
		
		// Add the new view offscreen
		view.frame = newViewRect
		self.addSubview(view)
		
		// Calculate the target frame of the new view
		var targetNewViewFrame = r
		if adjustWindow {
			targetNewViewFrame.size = newViewSize
		}
		
		view.animator().frame = targetNewViewFrame
		self.currentView!.animator().frame = toBeMoved
		
		NSAnimationContext.endGrouping()
		
		_otherView = self.currentView
		self.currentView = view
		
		Timer.scheduledTimer(timeInterval: NSAnimationContext.current.duration, target: self, selector: #selector(XUSwitchableView._unsetAnimation(_:)), userInfo: nil, repeats: false)
	}
    
}
