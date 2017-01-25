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
public final class XUArrayNotEmptyTransformer: ValueTransformer {
	
	public override func transformedValue(_ value: Any?) -> Any? {
		guard let arr = value as? [Any] else {
			return NSNumber(value: false)
		}
		
		return NSNumber(value: (arr.count > 0))
	}

}
