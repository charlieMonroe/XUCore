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

public func +=(lhs: inout NSDecimalNumber, rhs: Int) {
	lhs = lhs + rhs
}
public func -=(lhs: inout NSDecimalNumber, rhs: Int) {
	lhs = lhs - rhs
}
public func *=(lhs: inout NSDecimalNumber, rhs: Int) {
	lhs = lhs * rhs
}
public func /=(lhs: inout NSDecimalNumber, rhs: Int) {
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
	return lhs.adding(NSDecimalNumber(value: rhs))
}
public func -(lhs: NSDecimalNumber, rhs: Double) -> NSDecimalNumber {
	return lhs.subtracting(NSDecimalNumber(value: rhs))
}
public func *(lhs: NSDecimalNumber, rhs: Double) -> NSDecimalNumber {
	return lhs.multiplying(by: NSDecimalNumber(value: rhs))
}
public func /(lhs: NSDecimalNumber, rhs: Double) -> NSDecimalNumber {
	return lhs.dividing(by: NSDecimalNumber(value: rhs))
}

public func +(lhs: NSDecimalNumber, rhs: Int) -> NSDecimalNumber {
	return lhs.adding(NSDecimalNumber(value: rhs))
}
public func -(lhs: NSDecimalNumber, rhs: Int) -> NSDecimalNumber {
	return lhs.subtracting(NSDecimalNumber(value: rhs))
}
public func *(lhs: NSDecimalNumber, rhs: Int) -> NSDecimalNumber {
	return lhs.multiplying(by: NSDecimalNumber(value: rhs))
}
public func /(lhs: NSDecimalNumber, rhs: Int) -> NSDecimalNumber {
	return lhs.dividing(by: NSDecimalNumber(value: rhs))
}


public extension NSDecimalNumber {
	
	/// Creates NSDecimalNumber from value. Accepted values are nil (returns 0),
	/// NSDecimalNumber, (NS)String and NSNumber.
	convenience init(value: Any?) {
		if value == nil {
			self.init(value: Int(0))
			return
		}
		
		if let number = value as? NSDecimalNumber {
			self.init(decimal: number.decimalValue)
			return
		}
		
		if let str = value as? String {
			self.init(string: str)
			return
		}
		
		if let number = value as? NSNumber {
			self.init(decimal: number.decimalValue)
			return
		}
		
		XULogStacktrace("Trying to create NSDecimalNumber from unsupported kind of value \(value!)")
		self.init(value: Int(0))
	}
	
	/// Initializes self with a NSNumber instance.
	convenience init(number: NSNumber) {
		self.init(decimal: number.decimalValue)
	}
	
	/// Returns an absolute value of the decimal number.
	var absoluteValue: NSDecimalNumber {
		if self.doubleValue < 0.0 {
			return self * (-1.0)
		}
		
		return self
	}
	
	/// Returns a ceiled decimal number.
	var ceiled: NSDecimalNumber {
		return NSDecimalNumber(value: ceil(self.doubleValue))
	}
	
	/// Returns the decimal part - e.g. 5.32 --> 0.32.
	var decimalPart: NSDecimalNumber {
		return self - self.integralValue
	}
	
	/// Returns number without the decimal part.
	var integralValue: NSDecimalNumber {
		return NSDecimalNumber(value: floor(self.doubleValue))
	}
	
	/// Rounds the decimal number.
	var roundedDecimalNumber: NSDecimalNumber {
		return NSDecimalNumber(value: round(self.doubleValue))
	}
	
	/// Returns whether this number is an integer, i.e. is the decimalPart is 0.0
	var isInteger: Bool {
		return self.decimalPart.doubleValue == 0.0
	}
	
	/// Returns whether this number is less than 0.
	var isNegative: Bool {
		return self.doubleValue < 0.0
	}
	
	/// Returns whether this number is more or equal to 0.
	var isPositive: Bool {
		return self.doubleValue >= 0.0
	}
	
	/// Returns true is the current double value is 0.0
	var isZero: Bool {
		return self.doubleValue == 0.0
	}
		
}

