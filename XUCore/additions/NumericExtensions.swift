//
//  NumericExtensions.swift
//  XUCore
//
//  Created by Charlie Monroe on 6/13/18.
//  Copyright © 2018 Charlie Monroe Software. All rights reserved.
//

import Foundation

extension Numeric where Self: Comparable {
	
	/// Clamps the value to a range.
	public func clamped(to range: ClosedRange<Self>) -> Self {
		if self < range.lowerBound {
			return range.lowerBound
		}
		if range.upperBound < self {
			return range.upperBound
		}
		
		return self
	}
	
}
