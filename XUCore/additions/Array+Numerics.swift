//
//  Array+Numerics.swift
//  XUCore
//
//  Created by Charlie Monroe on 3/2/18.
//  Copyright © 2018 Charlie Monroe Software. All rights reserved.
//

import Foundation

extension Sequence {

	/// Sums up values of elements in self.
	public func sum<T: Numeric>(_ numerator: (Self.Iterator.Element) throws -> T) rethrows -> T {
		return try self.reduce(into: 0, { partialResult, element in
			partialResult += try numerator(element)
		})
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

extension Sequence where Self.Iterator.Element : Numeric {
	
	/// Sums up itself.
	public func sum() -> Self.Iterator.Element {
		return self.reduce(0, +)
	}
	
}
