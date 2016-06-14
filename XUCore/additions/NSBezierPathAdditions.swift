//
//  XUBezierPathAdditions.swift
//  XUCore
//
//  Created by Charlie Monroe on 5/17/16.
//  Copyright © 2016 Charlie Monroe Software. All rights reserved.
//

import Cocoa

@objc public enum XUDirection: Int {
	case LeftToRight
	case RightToLeft
	case BottomToTop
	case TopToBottom

	/// If the context is flipped, the opposite direction is returned for bottom/
	/// top.
	public var directionInCurrentGraphicsContext: XUDirection {
		guard let graphicsContext = NSGraphicsContext.currentContext() else {
			return self
		}

		if !graphicsContext.flipped {
			return self
		}

		if self == .BottomToTop {
			return .TopToBottom
		}
		if self == .TopToBottom {
			return .BottomToTop
		}

		return self
	}
}

public extension NSBezierPath {

	public func fillWithInnerShadow(shadow: NSShadow) {
		NSGraphicsContext.saveGraphicsState()

		var offset = shadow.shadowOffset
		let originalOffset = offset
		let radius = shadow.shadowBlurRadius

		let bounds = self.bounds.insetBy(dx: -(abs(offset.width) + radius), dy: -(abs(offset.height) + radius))
		offset.height += bounds.size.height

		shadow.shadowOffset = offset

		let transform = NSAffineTransform()
		if NSGraphicsContext.currentContext()!.flipped {
			transform.translateXBy(0, yBy: bounds.size.height)
		} else {
			transform.translateXBy(0, yBy: -bounds.size.height)
		}

		let drawingPath = NSBezierPath(rect: bounds)
		drawingPath.windingRule = .EvenOddWindingRule
		drawingPath.appendBezierPath(self)
		drawingPath.transformUsingAffineTransform(transform)

		self.addClip()

		shadow.set()

		NSColor.blackColor().set()

		drawingPath.fill()
		shadow.shadowOffset = originalOffset

		NSGraphicsContext.restoreGraphicsState()
	}

	public func drawBlurWithColor(color: NSColor, andRadius radius: CGFloat) {
		let bounds = self.bounds.insetBy(dx: -radius, dy: -radius)

		let shadow = NSShadow()
		shadow.shadowOffset = CGSize(width: 0, height: bounds.size.height)
		shadow.shadowBlurRadius = radius
		shadow.shadowColor = color

		let path = self.copy() as! NSBezierPath
		let transform = NSAffineTransform()
		if NSGraphicsContext.currentContext()!.flipped {
			transform.translateXBy(0, yBy: bounds.size.height)
		} else {
			transform.translateXBy(0, yBy: -bounds.size.height)
		}
		path.transformUsingAffineTransform(transform)

		NSGraphicsContext.saveGraphicsState()

		shadow.set()

		NSColor.blackColor().set()
		NSRectClip(bounds)

		path.fill()

		NSGraphicsContext.restoreGraphicsState()
	}

	public convenience init(triangleInRect rect: CGRect, direction: XUDirection) {
		self.init()

		let correctDirection = direction.directionInCurrentGraphicsContext
		switch correctDirection {
		case .BottomToTop:
			self.moveToPoint(CGPoint(x: rect.origin.x, y: rect.origin.y))
			self.lineToPoint(CGPoint(x: rect.maxX, y: rect.origin.y))
			self.lineToPoint(CGPoint(x: rect.origin.x + (rect.maxX - rect.origin.x) / 2.0, y: rect.maxY))
			self.closePath()
		case .TopToBottom:
			self.moveToPoint(CGPoint(x: rect.origin.x, y: rect.maxY))
			self.lineToPoint(CGPoint(x: rect.maxX, y: rect.maxY))
			self.lineToPoint(CGPoint(x: rect.origin.x + (rect.maxX - rect.origin.x) / 2.0, y: rect.minY))
			self.closePath()
		case .RightToLeft:
			self.moveToPoint(CGPoint(x: rect.origin.x, y: rect.maxY))
			self.lineToPoint(CGPoint(x: rect.minX, y: rect.minY))
			self.lineToPoint(CGPoint(x: rect.maxX, y: rect.origin.y + (rect.maxY - rect.origin.y) / 2.0))
			self.closePath()
		case .LeftToRight:
			self.moveToPoint(CGPoint(x: rect.maxX, y: rect.maxY))
			self.lineToPoint(CGPoint(x: rect.maxX, y: rect.minY))
			self.lineToPoint(CGPoint(x: rect.minX, y: rect.origin.y + (rect.maxY - rect.origin.y) / 2.0))
			self.closePath()
		}

	}

	public func strokeInside() {
		self.strokeInsideWithinRect(CGRect())
	}

	public func strokeInsideWithinRect(clipRect: CGRect) {
		let thisContext = NSGraphicsContext.currentContext()

		let lineWidth = self.lineWidth

		// Save the current graphics context.
		thisContext?.saveGraphicsState()

		// Double the stroke width, since -stroke centers strokes on paths.
		self.lineWidth = (lineWidth * 2.0)

		// Clip drawing to this path; draw nothing outwith the path.
		self.setClip()

		// Further clip drawing to clipRect, usually the view's frame.
		if clipRect.size.width > 0.0 && clipRect.size.height > 0.0 {
			NSBezierPath.clipRect(clipRect)
		}

		// Stroke the path.
		self.stroke()

		// Restore the previous graphics context.
		thisContext?.restoreGraphicsState()

		self.lineWidth = lineWidth
	}

}
