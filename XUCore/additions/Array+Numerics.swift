//
//  Array+Numerics.swift
//  XUCore
//
//  Created by Charlie Monroe on 3/2/18.
//  Copyright © 2018 Charlie Monroe Software. All rights reserved.
//

import Foundation

public extension Sequence {

	/// Sums up values of elements in self.
	public func sum<T: Numeric>(_ numerator: (Self.Iterator.Element) throws -> T) rethrows -> T {
		return try self.map(numerator).sum()
	}
	
	/// Sums up values of elements in self.
	public func sum(_ numerator: (Self.Iterator.Element) throws -> NSDecimalNumber) rethrows -> NSDecimalNumber {
		var result: NSDecimalNumber = NSDecimalNumber.zero
		for obj in self {
			result = try result.adding(numerator(obj))
		}
		return result
	}
	
}

public extension Sequence where Self.Iterator.Element : Numeric {
	
	/// Sums up itself.
	public func sum() -> Self.Iterator.Element {
		return self.reduce(0, +)
	}
	
}
