//
//  CGContextRefAdditions.swift
//  XUCore
//
//  Created by Charlie Monroe on 11/21/15.
//  Copyright © 2015 Charlie Monroe Software. All rights reserved.
//

#if os(iOS)
	import UIKit
#else
	import AppKit
#endif

public extension CGContext {
	
	/// Adds a rounded rect to the CGContextRef.
	public func addRoundedRect(in rect: CGRect, withCornerRadius cornerRadius: CGFloat) {
		let x_left = rect.minX
		let x_left_center = rect.minX + cornerRadius
		let x_right_center = rect.minX + rect.width - cornerRadius
		let x_right = rect.minX + rect.width
		let y_top = rect.minY
		let y_top_center = rect.minY + cornerRadius
		let y_bottom_center = rect.minY + rect.height - cornerRadius
		let y_bottom = rect.minY + rect.height
		
		/* Begin! */
		self.beginPath()
		self.move(to: CGPoint(x: x_left, y: y_top_center))
		
		/* First corner */
		self.addArc(tangent1End: CGPoint(x: x_left, y: y_top), tangent2End: CGPoint(x: x_left_center, y: y_top), radius: cornerRadius)
		self.addLine(to: CGPoint(x: x_right_center, y: y_top))
		
		/* Second corner */
		self.addArc(tangent1End: CGPoint(x: x_right, y: y_top), tangent2End: CGPoint(x: x_right, y: y_top_center), radius: cornerRadius)
		self.addLine(to: CGPoint(x: x_right, y: y_bottom_center))
		
		/* Third corner */
		self.addArc(tangent1End: CGPoint(x: x_right, y: y_bottom), tangent2End: CGPoint(x: x_right_center, y: y_bottom), radius: cornerRadius)
		self.addLine(to: CGPoint(x: x_left_center, y: y_bottom))
		
		/* Fourth corner */
		self.addArc(tangent1End: CGPoint(x: x_left, y: y_bottom), tangent2End: CGPoint(x: x_left, y: y_bottom_center), radius: cornerRadius)
		self.addLine(to: CGPoint(x: x_left, y: y_top_center))
		
		/* Done */
		self.closePath()
	}
	
}
