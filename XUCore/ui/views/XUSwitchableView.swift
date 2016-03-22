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

	//Only for debug purposes
	/*
	-(void)drawRect:(CGRect)dirtyRect{
		[[NSColor blueColor] set];
		CGRectFill(dirtyRect);
	}
	*/
	
	private var _isAnimating: Bool = false
	private var _otherView: NSView?
	
	
	@objc private func _frameChanged(sender: AnyObject?) {
		//! NSEqualRects([self bounds], [[self superview] bounds])
		if _isAnimating {
			return
		}
		
		self.currentView?.frame = self.bounds
		if _otherView != nil && !_otherView!.hidden {
			_otherView?.hidden = true
		}
	}
	
	@objc private func _unsetAnimation(sender: AnyObject?) {
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
		NSNotificationCenter.defaultCenter().removeObserver(self)
	}
	public override init(frame: CGRect) {
		super.init(frame: frame)
		
		self.postsFrameChangedNotifications = true
		NSNotificationCenter.defaultCenter().addObserver(self, selector: "_frameChanged:", name: NSViewFrameDidChangeNotification, object: self)
	}
	public required init?(coder: NSCoder) {
		super.init(coder: coder)
		
		self.postsFrameChangedNotifications = true
		NSNotificationCenter.defaultCenter().addObserver(self, selector: "_frameChanged:", name: NSViewFrameDidChangeNotification, object: self)
	}
	
	public override var mouseDownCanMoveWindow: Bool {
		return true
	}
	
	/// Switches to a new view in direction specified. Doesn't adjust window size.
	public func switchToView(view: NSView, inDirection direction: XUDirection) {
		self.switchToView(view, inDirection: direction, adjustWindow: false)
	}
	
	/// Switches to a new view in direction specified and if adjustWindow is true,
	/// the window size is adjusted as well.
	public func switchToView(view: NSView, inDirection direction: XUDirection, adjustWindow: Bool) {
		_isAnimating = true
		
		// Make sure the view isn't hidden
		if _otherView != nil && _otherView!.hidden {
			_otherView!.hidden = false
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
			case .LeftToRight:
				// From left to right
				newViewRect = CGRect(x: oldViewSize.width, y: oldViewSize.height - newViewSize.height, width: targetSize.width, height: targetSize.height)
				toBeMoved = CGRect(x: -oldViewSize.width, y: 0, width: oldViewSize.width, height: oldViewSize.height)
			case .RightToLeft:
				// From right to left
				newViewRect = CGRect(x: -newViewSize.width, y: oldViewSize.height - newViewSize.height, width: newViewSize.width, height: newViewSize.height)
				toBeMoved = CGRect(x: oldViewSize.width, y: 0, width: oldViewSize.width, height: oldViewSize.height)
			case .TopToBottom:
				// From up to down
				newViewRect = CGRect(x: 0, y: r.height, width: r.width, height: r.height)
				toBeMoved = CGRect(x: 0, y: -r.height, width: r.width, height: r.height)
			case .BottomToTop:
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
		
		NSTimer.scheduledTimerWithTimeInterval(NSAnimationContext.currentContext().duration, target: self, selector: "_unsetAnimation:", userInfo: nil, repeats: false)
	}
    
}

@available(*, deprecated)
@objc(FCSwitchableView) public class FCSwitchableView: XUSwitchableView {
	
	public override func awakeFromNib() {
		XULog("WARNING: Deprecated use of \(self.dynamicType) - use XUCore.\(self.superclass!) instead")
		
		super.awakeFromNib()
	}
	
}
