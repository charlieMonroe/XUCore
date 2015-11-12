//
//  XUAttributedStringTransformer.swift
//  XUCore
//
//  Created by Charlie Monroe on 11/6/15.
//  Copyright © 2015 Charlie Monroe Software. All rights reserved.
//

import Foundation

/// Transformed value returns an attributed string, reverse transformed value
/// returns a plain string. Always returns non-null value.
public class XUAttributedStringTransformer: NSValueTransformer {

	public override func reverseTransformedValue(value: AnyObject?) -> AnyObject? {
		if value == nil {
			return ""
		}
		
		if value is String || value is NSString {
			return value
		}
		
		if let attrStr = value as? NSAttributedString {
			return attrStr.string
		}
		
		return ""
	}
	
	public override func transformedValue(value: AnyObject?) -> AnyObject? {
		if value == nil {
			return ""
		}
		
		if value is NSAttributedString {
			return value
		}
		
		if let str = value as? String {
			return NSAttributedString(string: str)
		}
		
		return ""
	}
	
}


@objc(FCAttributedStringTransformer) public class FCAttributedStringTransformer: XUAttributedStringTransformer {
	
	
	public override func reverseTransformedValue(value: AnyObject?) -> AnyObject? {
		XULog("WARNING: Deprecated use of \(self.dynamicType) - use XUCore.\(self.superclass!) instead")
		
		return super.reverseTransformedValue(value)
	}
	public override func transformedValue(value: AnyObject?) -> AnyObject? {
		XULog("WARNING: Deprecated use of \(self.dynamicType) - use XUCore.\(self.superclass!) instead")
		
		return super.transformedValue(value)
	}
}

