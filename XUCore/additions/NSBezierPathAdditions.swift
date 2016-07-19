//
//  XUBezierPathAdditions.swift
//  XUCore
//
//  Created by Charlie Monroe on 5/17/16.
//  Copyright © 2016 Charlie Monroe Software. All rights reserved.
//

import Cocoa

public extension NSBezierPath {

	public func fillWithInnerShadow(shadow: NSShadow) {
		NSGraphicsContext.saveGraphicsState()

		var offset = shadow.shadowOffset
		let originalOffset = offset
		let radius = shadow.shadowBlurRadius

		let bounds = self.bounds.insetBy(dx: -(abs(offset.width) + radius), dy: -(abs(offset.height) + radius))
		offset.height += bounds.height

		shadow.shadowOffset = offset

		let transform = NSAffineTransform()
		if NSGraphicsContext.currentContext()!.flipped {
			transform.translateXBy(0, yBy: bounds.height)
		} else {
			transform.translateXBy(0, yBy: -bounds.height)
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
		shadow.shadowOffset = CGSize(width: 0, height: bounds.height)
		shadow.shadowBlurRadius = radius
		shadow.shadowColor = color

		let path = self.copy() as! NSBezierPath
		let transform = NSAffineTransform()
		if NSGraphicsContext.currentContext()!.flipped {
			transform.translateXBy(0, yBy: bounds.height)
		} else {
			transform.translateXBy(0, yBy: -bounds.height)
		}
		path.transformUsingAffineTransform(transform)

		NSGraphicsContext.saveGraphicsState()

		shadow.set()

		NSColor.blackColor().set()
		NSRectClip(bounds)

		path.fill()

		NSGraphicsContext.restoreGraphicsState()
	}

	public convenience init(roundedPointingRect inRect: CGRect, triangleCenteredToRect centerRect: CGRect, windowFrame: CGRect, cornerRadius radius: CGFloat) {
		
		let triangleTopX = centerRect.minX - windowFrame.minX + centerRect.width / 2.0
		let inRadiusX = radius
		let inRadiusY = radius
		let kEllipseFactor: CGFloat = 0.55228474983079
		let theMaxRadiusX = inRect.width / 2.0
		let theMaxRadiusY = inRect.height / 2.0
		let theRadiusX = (inRadiusX < theMaxRadiusX) ? inRadiusX : theMaxRadiusX
		let theRadiusY = (inRadiusY < theMaxRadiusY) ? inRadiusY : theMaxRadiusY
		let theControlX = theRadiusX * kEllipseFactor
		let theControlY = theRadiusY * kEllipseFactor
		let theEdges = inRect.insetBy(dx: theRadiusX, dy: theRadiusY)
		
		self.init()
		
		// Lower edge and lower-right corner
		self.moveToPoint(CGPoint(x: theEdges.minX, y: inRect.minY))
		self.lineToPoint(CGPoint(x: theEdges.maxX, y: inRect.minY))
		self.curveToPoint(CGPoint(x: inRect.maxX, y: theEdges.minY), controlPoint1: CGPoint(x: theEdges.maxX + theControlX, y: inRect.minY), controlPoint2: CGPoint(x: inRect.maxX, y: theEdges.minY - theControlY))
		
		// Right edge and upper-right corner
		self.lineToPoint(CGPoint(x: inRect.maxX, y: theEdges.maxY))
		self.curveToPoint(CGPoint(x: theEdges.maxX, y: inRect.maxY), controlPoint1: CGPoint(x: inRect.maxX, y: theEdges.maxY + theControlY), controlPoint2: CGPoint(x: theEdges.maxX + theControlX, y: inRect.maxY))
		
		// triangle:
		// Right edge
		self.lineToPoint(CGPoint(x: triangleTopX + 14.0 - inRect.minX / 2.0, y: inRect.minY + inRect.height))
		
		// Center
		self.lineToPoint(CGPoint(x: triangleTopX, y: inRect.minY / 2.0 + inRect.height + 14.0))
		
		// Left edge
		self.lineToPoint(CGPoint(x: triangleTopX - 14.0 + inRect.minX / 2.0, y: inRect.minY + inRect.height))
		
		// Top edge and upper-left corner
		self.lineToPoint(CGPoint(x: theEdges.minX, y: inRect.maxY))
		self.curveToPoint(CGPoint(x: inRect.minX, y: theEdges.maxY), controlPoint1: CGPoint(x: theEdges.minX - theControlX, y: inRect.maxY), controlPoint2: CGPoint(x: inRect.minX, y: theEdges.maxY + theControlY))
		
		// Left edge and lower-left corner
		self.lineToPoint(CGPoint(x: inRect.minX, y: theEdges.minY))
		self.curveToPoint(CGPoint(x: theEdges.minX, y: inRect.minY), controlPoint1: CGPoint(x: inRect.minX, y: theEdges.minY - theControlY), controlPoint2: CGPoint(x: theEdges.minX - theControlX, y: inRect.minY))
		
		// Finish up and return
		self.closePath()
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
		if clipRect.width > 0.0 && clipRect.height > 0.0 {
			NSBezierPath.clipRect(clipRect)
		}

		// Stroke the path.
		self.stroke()

		// Restore the previous graphics context.
		thisContext?.restoreGraphicsState()

		self.lineWidth = lineWidth
	}

}
