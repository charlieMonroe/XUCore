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
open class XUAttributedStringTransformer: ValueTransformer {

	open override func reverseTransformedValue(_ value: Any?) -> Any? {
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
	
	open override func transformedValue(_ value: Any?) -> Any? {
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
