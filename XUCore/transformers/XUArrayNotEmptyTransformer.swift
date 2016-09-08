//
//  XUArrayNotEmptyTransformer.swift
//  XUCore
//
//  Created by Charlie Monroe on 11/6/15.
//  Copyright © 2015 Charlie Monroe Software. All rights reserved.
//

import Foundation

/// Transforms the value into Bool. If the value is an array and it is not empty,
/// true is returned, false otherwise.
open class XUArrayNotEmptyTransformer: ValueTransformer {
	
	open override func transformedValue(_ value: Any?) -> Any? {
		guard let arr = value as? Array<Any> else {
			return NSNumber(value: false as Bool)
		}
		
		return NSNumber(value: (arr.count > 0) as Bool)
	}

}
