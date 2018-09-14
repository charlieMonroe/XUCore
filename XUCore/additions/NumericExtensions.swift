//
//  NumericExtensions.swift
//  XUCore
//
//  Created by Charlie Monroe on 6/13/18.
//  Copyright © 2018 Charlie Monroe Software. All rights reserved.
//

import Foundation

extension FloatingPoint {
	
	/// Returns true if the number is integral. This is based on rounding both
	/// up and down is the same number. Returns false for non-finite numbers.
	public var isIntegral: Bool {
		guard self.isFinite else {
			return false
		}
		return self.rounded(.down) == self.rounded(.up)
	}
	
}

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
