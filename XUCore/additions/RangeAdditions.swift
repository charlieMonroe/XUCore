//
//  RangeAdditions.swift
//  XUCore
//
//  Created by Charlie Monroe on 7/24/18.
//  Copyright © 2018 Charlie Monroe Software. All rights reserved.
//

import Foundation

extension Range where Bound: FixedWidthInteger {
	
	/// Converts the range to a range of different type by casting the lower
	/// and upper bounds. Does not check for ranges.
	public func converted<T: FixedWidthInteger>(to type: T.Type) -> Range<T> {
		return Range<T>(uncheckedBounds: (lower: T.init(self.lowerBound), upper: T.init(self.upperBound)))
	}
	
}
