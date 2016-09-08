//
//  NSDecimalNumberAdditions.swift
//  XUCore
//
//  Created by Charlie Monroe on 11/9/15.
//  Copyright © 2015 Charlie Monroe Software. All rights reserved.
//

import Foundation


public func <(lhs: NSDecimalNumber, rhs: NSDecimalNumber) -> Bool {
	return lhs.doubleValue < rhs.doubleValue
}
public func <(lhs: NSDecimalNumber, rhs: Double) -> Bool {
	return lhs.doubleValue < rhs
}

public func >(lhs: NSDecimalNumber, rhs: NSDecimalNumber) -> Bool {
	return lhs.doubleValue > rhs.doubleValue
}
public func >(lhs: NSDecimalNumber, rhs: Double) -> Bool {
	return lhs.doubleValue > rhs
}


public func <=(lhs: NSDecimalNumber, rhs: NSDecimalNumber) -> Bool {
	return lhs.doubleValue <= rhs.doubleValue
}
public func <=(lhs: NSDecimalNumber, rhs: Double) -> Bool {
	return lhs.doubleValue <= rhs
}


public func >=(lhs: NSDecimalNumber, rhs: NSDecimalNumber) -> Bool {
	return lhs.doubleValue >= rhs.doubleValue
}
public func >=(lhs: NSDecimalNumber, rhs: Double) -> Bool {
	return lhs.doubleValue >= rhs
}


public func +=(lhs: inout NSDecimalNumber, rhs: NSDecimalNumber) {
	lhs = lhs + rhs
}
public func -=(lhs: inout NSDecimalNumber, rhs: NSDecimalNumber) {
	lhs = lhs - rhs
}
public func *=(lhs: inout NSDecimalNumber, rhs: NSDecimalNumber) {
	lhs = lhs * rhs
}
public func /=(lhs: inout NSDecimalNumber, rhs: NSDecimalNumber) {
	lhs = lhs / rhs
}

public func +=(lhs: inout NSDecimalNumber, rhs: Double) {
	lhs = lhs + rhs
}
public func -=(lhs: inout NSDecimalNumber, rhs: Double) {
	lhs = lhs - rhs
}
public func *=(lhs: inout NSDecimalNumber, rhs: Double) {
	lhs = lhs * rhs
}
public func /=(lhs: inout NSDecimalNumber, rhs: Double) {
	lhs = lhs / rhs
}

public func +(lhs: NSDecimalNumber, rhs: NSDecimalNumber) -> NSDecimalNumber {
	return lhs.adding(rhs)
}
public func -(lhs: NSDecimalNumber, rhs: NSDecimalNumber) -> NSDecimalNumber {
	return lhs.subtracting(rhs)
}
public func *(lhs: NSDecimalNumber, rhs: NSDecimalNumber) -> NSDecimalNumber {
	return lhs.multiplying(by: rhs)
}
public func /(lhs: NSDecimalNumber, rhs: NSDecimalNumber) -> NSDecimalNumber {
	return lhs.dividing(by: rhs)
}

public func +(lhs: NSDecimalNumber, rhs: Double) -> NSDecimalNumber {
	return lhs.adding(NSDecimalNumber(value: rhs as Double))
}
public func -(lhs: NSDecimalNumber, rhs: Double) -> NSDecimalNumber {
	return lhs.subtracting(NSDecimalNumber(value: rhs as Double))
}
public func *(lhs: NSDecimalNumber, rhs: Double) -> NSDecimalNumber {
	return lhs.multiplying(by: NSDecimalNumber(value: rhs as Double))
}
public func /(lhs: NSDecimalNumber, rhs: Double) -> NSDecimalNumber {
	return lhs.dividing(by: NSDecimalNumber(value: rhs as Double))
}

public extension NSDecimalNumber {
	
	public class func decimalNumberWithDouble(_ value: Double) -> NSDecimalNumber {
		return self.decimalNumberWithNumber(value as NSNumber?)
	}
	public class func decimalNumberWithNumber(_ number: NSNumber?) -> NSDecimalNumber {
		if number == nil {
			return NSDecimalNumber.zero
		}
		
		if let decimal = number as? NSDecimalNumber {
			return decimal
		}
		
		return NSDecimalNumber(decimal: number!.decimalValue)
	}
	
	/// Creates NSDecimalNumber from value. Accepted values are nil (returns 0),
	/// NSDecimalNumber, (NS)String and NSNumber.
	public class func decimalNumberWithValue(_ value: AnyObject?) -> NSDecimalNumber {
		if value == nil {
			return NSDecimalNumber.zero
		}
		
		if let number = value as? NSDecimalNumber {
			return number
		}
		
		if let str = value as? String {
			return NSDecimalNumber(string: str)
		}
		
		if let number = value as? NSNumber {
			return NSDecimalNumber.decimalNumberWithNumber(number)
		}
		
		XULogStacktrace("Trying to create NSDecimalNumber from unsupported kind of value \(value!)")
		return NSDecimalNumber.zero
	}
	
	
	/// Returns an absolute value of the decimal number.
	public var absoluteValueDecimalNumber: NSDecimalNumber {
		if self.doubleValue < 0.0 {
			return self * (-1.0)
		}
		
		return self
	}
	
	/// Returns a ceiled decimal number.
	public var ceiledDecimalNumber: NSDecimalNumber {
		if self.decimalPart.doubleValue < 0.01 {
			/* Consider self already ceiled. */
			return self
		}
		
		return NSDecimalNumber(value: ceil(self.doubleValue) as Double)
	}
	
	/// Returns the decimal part - e.g. 5.32 --> 0.32.
	public var decimalPart: NSDecimalNumber {
		return self - self.integralDecimalNumber
	}
	
	/// Returns number without the decimal part.
	public var integralDecimalNumber: NSDecimalNumber {
		return NSDecimalNumber(value: Double(Int(self.doubleValue)) as Double)
	}
	
	/// Rounds the decimal number.
	public var roundedDecimalNumber: NSDecimalNumber {
		if self.decimalPart.doubleValue < 0.01 {
			/* Consider self already rounded. */
			return self
		}
		return NSDecimalNumber(value: round(self.doubleValue) as Double)
	}
	
	/// Returns whether this number is an integer, i.e. is the decimalPart is 0.0
	public var isInteger: Bool {
		return self.decimalPart.doubleValue == 0.0
	}
	
	/// Returns whether this number is less than 0.
	public var isNegative: Bool {
		return self.doubleValue < 0.0
	}
	
	/// Returns whether this number is more or equal to 0.
	public var isPositive: Bool {
		return self.doubleValue >= 0.0
	}
	
	/// Returns true is the current double value is 0.0
	public var isZero: Bool {
		return self.doubleValue == 0.0
	}
	
}

