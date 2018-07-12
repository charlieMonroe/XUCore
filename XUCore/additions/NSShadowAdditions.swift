//
//  NSShadowAdditions.swift
//  XUCore
//
//  Created by Charlie Monroe on 11/10/15.
//  Copyright © 2015 Charlie Monroe Software. All rights reserved.
//

#if os(macOS)
	import AppKit
	public typealias __XUBridgedColor = NSColor
#else
	import UIKit
	public typealias __XUBridgedColor = UIColor
#endif

public extension NSShadow {
	
	public convenience init(color: __XUBridgedColor, offset: CGSize, blurRadius: CGFloat) {
		self.init()
		
		self.shadowColor = color
		self.shadowOffset = offset
		self.shadowBlurRadius = blurRadius
	}
	
}
