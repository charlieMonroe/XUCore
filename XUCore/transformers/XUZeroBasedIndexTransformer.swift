//
//  XUZeroBasedIndexTransformer.swift
//  XUCore
//
//  Created by Charlie Monroe on 11/6/15.
//  Copyright © 2015 Charlie Monroe Software. All rights reserved.
//

import Foundation

/// Converts the value (must be NSNumber) as +1 and reverse -1.
open class XUZeroBasedIndexTransformer: ValueTransformer {
	
	open override func reverseTransformedValue(_ value: Any?) -> Any? {
		guard let number = value as? NSNumber else {
			NSException(name: NSExceptionName.internalInconsistencyException, reason: "XUZeroBasedIndexTransformer: wrong value type (reverse)", userInfo: nil).raise()
			return nil
		}
		
		return NSNumber(value: number.intValue - 1 as Int)
	}
	open override func transformedValue(_ value: Any?) -> Any? {
		guard let number = value as? NSNumber else {
			NSException(name: NSExceptionName.internalInconsistencyException, reason: "XUZeroBasedIndexTransformer: wrong value type (reverse)", userInfo: nil).raise()
			return nil
		}
		
		return NSNumber(value: number.intValue + 1 as Int)
	}

}
