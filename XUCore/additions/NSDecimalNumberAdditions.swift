//
//  NSDecimalNumberAdditions.swift
//  XUCore
//
//  Created by Charlie Monroe on 11/9/15.
//  Copyright © 2015 Charlie Monroe Software. All rights reserved.
//

import Foundation


public extension NSDecimalNumber {
	
	public override class func initialize() {
		self.setDefaultBehavior(NSDecimalNumberHandler(roundingMode: .RoundBankers, scale: 8, raiseOnExactness: false, raiseOnOverflow: false, raiseOnUnderflow: false, raiseOnDivideByZero: false))
	}
	
	public class func decimalNumberWithDouble(value: Double) -> NSDecimalNumber {
		return self.decimalNumberWithNumber(value)
	}
	public class func decimalNumberWithNumber(number: NSNumber?) -> NSDecimalNumber {
		if number == nil {
			return NSDecimalNumber.zero()
		}
		
		if let decimal = number as? NSDecimalNumber {
			return decimal
		}
		
		return NSDecimalNumber(decimal: number!.decimalValue)
	}
	
	/// Creates NSDecimalNumber from value. Accepted values are nil (returns 0),
	/// NSDecimalNumber, (NS)String and NSNumber.
	public class func decimalNumberWithValue(value: AnyObject?) -> NSDecimalNumber {
		if value == nil {
			return NSDecimalNumber.zero()
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
		return NSDecimalNumber.zero()
	}
	
	/// Returns a ceiled decimal number.
	public var ceiledDecimalNumber: NSDecimalNumber {
		if self.decimalPart.doubleValue < 0.01 {
			/* Consider self already ceiled. */
			return self
		}
		
		return NSDecimalNumber(double: ceil(self.doubleValue))
	}
	
	/// Returns the decimal part - e.g. 5.32 --> 0.32.
	public var decimalPart: NSDecimalNumber {
		return self.subtractDecimal(self.integralDecimalNumber)
	}
	
	/// Returns number without the decimal part.
	public var integralDecimalNumber: NSDecimalNumber {
		return NSDecimalNumber(double: Double(Int(self.doubleValue)))
	}
	
	/// Rounds the decimal number.
	public var roundedDecimalNumber: NSDecimalNumber {
		if self.decimalPart.doubleValue < 0.01 {
			/* Consider self already rounded. */
			return self
		}
		return NSDecimalNumber(double: round(self.doubleValue))
	}
	
	public func add(value: Double) -> NSDecimalNumber {
		return self.decimalNumberByAdding(NSDecimalNumber(double: value))
	}
	public func divide(value: Double) -> NSDecimalNumber {
		return self.decimalNumberByDividingBy(NSDecimalNumber(double: value))
	}
	public func multiply(value: Double) -> NSDecimalNumber {
		return self.decimalNumberByMultiplyingBy(NSDecimalNumber(double: value))
	}
	public func subtract(value: Double) -> NSDecimalNumber {
		return self.decimalNumberBySubtracting(NSDecimalNumber(double: value))
	}
	
	public var absoluteValueDecimalNumber: NSDecimalNumber {
		if self.doubleValue < 0.0 {
			return self.multiply(-1.0)
		}
		
		return self
	}
	
	public func addDecimal(value: NSDecimalNumber?) -> NSDecimalNumber {
		if value == nil {
			return self
		}
		return self.decimalNumberByAdding(value!)
	}
	
	public func divideDecimal(value: NSDecimalNumber?) -> NSDecimalNumber {
		if value == nil {
			return NSDecimalNumber.notANumber()
		}
		
		return self.decimalNumberByDividingBy(value!)
	}
	
	public func multiplyDecimal(value: NSDecimalNumber?) -> NSDecimalNumber {
		if value == nil {
			return NSDecimalNumber.zero()
		}
		
		return self.decimalNumberByMultiplyingBy(value!)
	}
	
	public func subtractDecimal(value: NSDecimalNumber?) -> NSDecimalNumber {
		if value == nil {
			return self
		}
		
		return self.decimalNumberBySubtracting(value!)
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
	
}


