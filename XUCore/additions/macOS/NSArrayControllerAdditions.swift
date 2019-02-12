//
//  NSArrayControllerAdditions.swift
//  XUCore
//
//  Created by Charlie Monroe on 10/4/16.
//  Copyright © 2016 Charlie Monroe Software. All rights reserved.
//

import Cocoa

public extension NSArrayController {
	
	/// There are currently several issues with NSArrayController since it returns
	/// an array proxy and the cast to Swift array of e.g. an array of protocol
	/// that isn't explicitly @objc fails with fatalError. A fix to this is to
	/// have an intermediate cast to [AnyObject] (given that it's an ObjC API,
	/// it's definitely an array of objects).
	var arrangedObjects_fix: [AnyObject] {
		return (self.arrangedObjects as? [AnyObject]) ?? []
	}
	
}

