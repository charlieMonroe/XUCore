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

/// Adds a rounded rect to the CGContextRef.
public func CGContextAddRoundedRect(c: CGContextRef, rect: CGRect, cornerRadius: CGFloat) {
	let x_left = rect.origin.x
	let x_left_center = rect.origin.x + cornerRadius
	let x_right_center = rect.origin.x + rect.width - cornerRadius
	let x_right = rect.origin.x + rect.width
	let y_top = rect.origin.y
	let y_top_center = rect.origin.y + cornerRadius
	let y_bottom_center = rect.origin.y + rect.size.height - cornerRadius
	let y_bottom = rect.origin.y + rect.size.height
	
	/* Begin! */
	CGContextBeginPath(c)
	CGContextMoveToPoint(c, x_left, y_top_center)
	
	/* First corner */
	CGContextAddArcToPoint(c, x_left, y_top, x_left_center, y_top, cornerRadius)
	CGContextAddLineToPoint(c, x_right_center, y_top)
	
	/* Second corner */
	CGContextAddArcToPoint(c, x_right, y_top, x_right, y_top_center, cornerRadius)
	CGContextAddLineToPoint(c, x_right, y_bottom_center)
	
	/* Third corner */
	CGContextAddArcToPoint(c, x_right, y_bottom, x_right_center, y_bottom, cornerRadius)
	CGContextAddLineToPoint(c, x_left_center, y_bottom)
	
	/* Fourth corner */
	CGContextAddArcToPoint(c, x_left, y_bottom, x_left, y_bottom_center, cornerRadius)
	CGContextAddLineToPoint(c, x_left, y_top_center)
	
	/* Done */
	CGContextClosePath(c)
}
