//
//  NSShadowAdditions.swift
//  XUCore
//
//  Created by Charlie Monroe on 11/10/15.
//  Copyright © 2015 Charlie Monroe Software. All rights reserved.
//

#if os(macOS)
	import AppKit
#else
	import UIKit
#endif

public extension NSShadow {
	
	public convenience init(color: NSColor, offset: CGSize, blurRadius: CGFloat) {
		self.init()
		
		self.shadowColor = color
		self.shadowOffset = offset
		self.shadowBlurRadius = blurRadius
	}
	
}
