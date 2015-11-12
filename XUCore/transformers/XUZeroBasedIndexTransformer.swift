//
//  XUZeroBasedIndexTransformer.swift
//  XUCore
//
//  Created by Charlie Monroe on 11/6/15.
//  Copyright © 2015 Charlie Monroe Software. All rights reserved.
//

import Foundation

/// Converts the value (must be NSNumber) as +1 and reverse -1.
public class XUZeroBasedIndexTransformer: NSValueTransformer {
	
	public override func reverseTransformedValue(value: AnyObject?) -> AnyObject? {
		guard let number = value as? NSNumber else {
			NSException(name: NSInternalInconsistencyException, reason: "XUZeroBasedIndexTransformer: wrong value type (reverse)", userInfo: nil).raise()
			return nil
		}
		
		return NSNumber(integer: number.integerValue - 1)
	}
	public override func transformedValue(value: AnyObject?) -> AnyObject? {
		guard let number = value as? NSNumber else {
			NSException(name: NSInternalInconsistencyException, reason: "XUZeroBasedIndexTransformer: wrong value type (reverse)", userInfo: nil).raise()
			return nil
		}
		
		return NSNumber(integer: number.integerValue + 1)
	}

}

@objc(FCZeroBasedIndexTransformer) public class FCZeroBasedIndexTransformer: XUZeroBasedIndexTransformer {
	
	public override func reverseTransformedValue(value: AnyObject?) -> AnyObject? {
		XULog("WARNING: Deprecated use of \(self.dynamicType) - use XUCore.\(self.superclass!) instead")
		
		return super.reverseTransformedValue(value)
	}
	public override func transformedValue(value: AnyObject?) -> AnyObject? {
		XULog("WARNING: Deprecated use of \(self.dynamicType) - use XUCore.\(self.superclass!) instead")
		
		return super.transformedValue(value)
	}
	
}

