//
//  NSRunningApplicationAdditions.swift
//  XUCore
//
//  Created by Charlie Monroe on 1/13/16.
//  Copyright © 2016 Charlie Monroe Software. All rights reserved.
//

import Cocoa

public extension NSRunningApplication {
	
	/// A covenience var for getting the frontmost application.
	class var frontmostApplication: NSRunningApplication! {
		return NSWorkspace.shared.frontmostApplication
	}
	
}
