//
//  XUArrayNotEmptyTransformer.swift
//  XUCore
//
//  Created by Charlie Monroe on 11/6/15.
//  Copyright © 2015 Charlie Monroe Software. All rights reserved.
//

import Cocoa

/// Transforms the value into Bool. If the value is an array and it is not empty,
/// true is returned, false otherwise.
public class XUArrayNotEmptyTransformer: NSValueTransformer {
	
	public override func transformedValue(value: AnyObject?) -> AnyObject? {
		guard let arr = value as? Array<Any> else {
			return NSNumber(bool: false)
		}
		
		return NSNumber(bool: arr.count > 0)
	}

}

@objc(FCArrayNotEmpty) public class FCArrayNotEmpty: XUArrayNotEmptyTransformer {
	
	public override func transformedValue(value: AnyObject?) -> AnyObject? {
		FCLog("WARNING: Deprecated use of \(self.dynamicType) - use XUCore.\(self.superclass!) instead")
		
		return super.transformedValue(value)
	}
	
}

