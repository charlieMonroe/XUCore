//
//  OptionalAdditions.swift
//  XUCore
//
//  Created by Charlie Monroe on 6/16/16.
//  Copyright © 2016 Charlie Monroe Software. All rights reserved.
//

import Foundation

private protocol _XUOptional {}
extension Optional: _XUOptional {}

infix operator ?=

/// Nil coalescing infix operator. Usage:
///
/// var x: Int? = nil
/// x ?= 9
///
/// x == 9
///
public func ?=<T>(_ lhs: inout T?, _ rhs: T?) {
	if lhs != nil {
		return
	}
	
	lhs = rhs
}

/// Returns true if anyValue represents an optional.
public func isOptional(_ anyValue: Any) -> Bool {
	return anyValue is _XUOptional
}

/// If anyValue is an Optional, it will be returned.
public func asOptional<T>(_ anyValue: Any) -> T? {
	if let val = anyValue as? T {
		return val
	}
	return nil
}

public extension String {
	
	@available(*, deprecated, message: "Interpolation of optionals is deprecated.")
	init<T>(stringInterpolationSegment segment: Optional<T>) {
		self = String(describing: segment)
	}
	
}

public extension Optional {

	/// Returns a description which returns defaultValue for nil and "value" for
	/// non-nil values.
	func descriptionWithDefaultValue(_ defaultValue: String = "nil") -> String {
		if self == nil {
			return String(defaultValue)
		} else {
			return String(describing: self!)
		}
	}
	
	/// Returns description that is "nil" for nil value and "Optional(value)" for
	/// non-nil values.
	var detailedDescription: String {
		return self.debugDescription
	}
	
}

public extension Optional where Wrapped: Collection {
	
	/// Returns true if the string wrapped in this optional is either nil or empty.
	var isNilOrEmpty: Bool {
		switch self {
		case .none:
			return true
		case .some(let collection):
			return collection.isEmpty
		}
	}
	
	/// Returns values of the collection, or an empty array if self is nil. This
	/// allows you to do stuff like `for x in optional.values { ... }`.
	var values: [Wrapped.Element] {
		switch self {
		case .none:
			return []
		case .some(let collection):
			return Array(collection)
		}
	}
	
}

