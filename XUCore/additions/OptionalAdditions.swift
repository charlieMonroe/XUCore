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
	public init<T>(stringInterpolationSegment segment: Optional<T>) {
		self.init(stringInterpolationSegment: segment as Any)
	}
	
}

public extension Optional {

	/// Returns a description which returns defaultValue for nil and "value" for
	/// non-nil values.
	public func descriptionWithDefaultValue(_ defaultValue: String = "nil") -> String {
		if self == nil {
			return String(defaultValue)
		} else {
			return String(describing: self!)
		}
	}
	
	/// Returns description that is "nil" for nil value and "Optional(value)" for
	/// non-nil values.
	public var detailedDescription: String {
		return self.debugDescription
	}
	
}

