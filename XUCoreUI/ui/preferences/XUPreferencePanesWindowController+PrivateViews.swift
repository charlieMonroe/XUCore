//
//  XUPreferencePanesWindowController+PrivateViews.swift
//  XUCoreUI
//
//  Created by Charlie Monroe on 5/11/22.
//  Copyright © 2022 Charlie Monroe Software. All rights reserved.
//

import AppKit

@objc(XUPreferencePanesWindowController_ShadowView)
private class ShadowView: NSView {
	
	@IBInspectable var isShadowFlipped: Bool = false
	
	override func draw(_ dirtyRect: NSRect) {
		if self.isShadowFlipped {
			let y = -(self.frame.height / 2.0)
			
			let bpath = NSBezierPath(ovalIn: CGRect(x: 0.0, y: y, width: self.frame.width, height: self.frame.height / 2.0))
			bpath.lineWidth = 0.0
			
			let shadow = NSShadow(color: .black, offset: CGSize(width: 0.0, height: 3.0), blurRadius: 6.0)
			shadow.set()
			
			NSColor.black.withAlphaComponent(0.15).setFill()
			
			bpath.fill()
			bpath.stroke()
		} else {
			let y = self.frame.height + 1.0
			
			let bpath = NSBezierPath(ovalIn: CGRect(x: 0.0, y: y, width: self.frame.width, height: self.frame.height))
			bpath.lineWidth = 0.0
			let shadow = NSShadow(color: .black, offset: CGSize(width: 0.0, height: -3.0), blurRadius: 6.0)
			shadow.set()
			bpath.stroke()
		}
	}
	
}

private func debug(_ string: String) {
	// print(string)
}

@objc(XUPreferencePanesWindowController_FlippedClipView)
private class _FlippedClipView: NSClipView {
	
	@IBOutlet private weak var _topShadowView: NSView!
	@IBOutlet private weak var _bottomShadowView: NSView!
	
	override var isFlipped: Bool {
		return true
	}
	
	override func scroll(to newOrigin: CGPoint) {
		super.scroll(to: newOrigin)
		
		let rect = self.documentVisibleRect
		
		debug("Scroll:")
		debug("\tVisible rect: \(rect)")
		debug("\tDocument rect: \(self.documentRect)")
		debug("\tDocument is flipped: \(self.documentView?.isFlipped ?? false)")

		if
			let topConstraint = _topShadowView?.superview?.constraints.first(where: { $0.firstAttribute == .top && ($0.firstItem === _topShadowView || $0.secondItem === _topShadowView) })
		{
			topConstraint.constant = self.contentInsets.top
		}
		
		if rect.height >= self.documentRect.height {
			debug("\tVisible rect smaller than document rect, hiding shadows.")
			_topShadowView.isHidden = true
			_bottomShadowView.isHidden = true
			return
		}
		
		if self.documentView?.isFlipped ?? false {
			// If it's flipped, when we're at the very top, we get:
			//
			// 	Visible rect: (0.0, -52.0, 258.0, 628.0)
			//
			// for top inset 52.0.
			
			debug("\tAdjusted y: \(rect.origin.y + self.contentInsets.top)")
			if rect.origin.y + self.contentInsets.top > 0.0 {
				_topShadowView.isHidden = false
				_topShadowView.alphaValue = min(1.0, (rect.origin.y + self.contentInsets.top) / _topShadowView.frame.height)
				debug("\tShowing top shadow with alpha: \(_topShadowView.alphaValue)")
			} else {
				_topShadowView.isHidden = true
				debug("\tHiding top shadow")
			}
					
			if rect.maxY < self.documentRect.height {
				_bottomShadowView.isHidden = false
				_bottomShadowView.alphaValue = min(1.0, (self.documentRect.height - rect.maxY) / _bottomShadowView.frame.height)
				
				debug("\tBottom Alpha: \(_bottomShadowView.alphaValue)")
			} else {
				debug("\tBottom: hiding")
				_bottomShadowView.isHidden = true
			}
		} else {
			if rect.origin.y > 0.0 {
				_bottomShadowView.isHidden = false
				_bottomShadowView.alphaValue = min(1.0, rect.origin.y / _bottomShadowView.frame.height)
			} else {
				_bottomShadowView.isHidden = true
			}
					
			if rect.maxY < self.documentRect.height {
				_topShadowView.isHidden = false
				_topShadowView.alphaValue = min(1.0, (self.documentRect.height - rect.maxY) / _topShadowView.frame.height)
				
				debug("\tTop Alpha: \(_topShadowView.alphaValue)")
			} else {
				debug("\tTop: hiding")
				_topShadowView.isHidden = true
			}
		}
	}
	
}

