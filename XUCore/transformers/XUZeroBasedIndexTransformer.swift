//
//  XUZeroBasedIndexTransformer.swift
//  XUCore
//
//  Created by Charlie Monroe on 11/6/15.
//  Copyright © 2015 Charlie Monroe Software. All rights reserved.
//

import Foundation

/// Converts the value (must be NSNumber) as +1 and reverse -1.
public final class XUZeroBasedIndexTransformer: ValueTransformer {
	
	public override func reverseTransformedValue(_ value: Any?) -> Any? {
		guard let number = value as? NSNumber else {
			fatalError("XUZeroBasedIndexTransformer: wrong value type (reverse).")
		}
		
		return NSNumber(value: number.intValue - 1)
	}
	
	public override func transformedValue(_ value: Any?) -> Any? {
		guard let number = value as? NSNumber else {
			fatalError("XUZeroBasedIndexTransformer: wrong value type.")
		}
		
		return NSNumber(value: number.intValue + 1)
	}

}
