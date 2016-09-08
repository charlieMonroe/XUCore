//
//  XURandomGenerator.swift
//  XUCore
//
//  Created by Charlie Monroe on 11/5/15.
//  Copyright © 2015 Charlie Monroe Software. All rights reserved.
//

import Foundation

/// Random number generator based on random() - where the seed is set in init
/// to something random
open class XURandomGenerator: NSObject {

	/// Returns a shared generator.
	open static let sharedGenerator = XURandomGenerator()
	
	public override init() {
		super.init()
		
		var tv: timeval = timeval(tv_sec: 0, tv_usec: 0)
		gettimeofday(&tv, nil)
		
		srandom(UInt32(((Int(getpid()) << 16) ^ tv.tv_sec ^ Int(tv.tv_usec)) % Int(UInt16.max)))
	}
	
	/// Returns a random boolean. Does so by getting a random byte and returning
	/// byte % 2 == 0
	open var randomBool: Bool {
		return self.randomByte % 2 == 0
	}
	
	/// Returns a random byte.
	open var randomByte: UInt8 {
		return UInt8(arc4random() % 256)
	}
	
	/// Returns a random unsigned integer.
	open var randomUnsignedInteger: UInt {
		return UInt(arc4random())
	}
	
	/// Returns an unsigned integer in range.
	open func randomUnsignedIntegerInRange(_ range: Range<UInt>) -> UInt {
		return range.lowerBound + (self.randomUnsignedInteger % UInt(range.count))
	}
	
	/// Returns an unsigned integer of max value.
	open func randomUnsignedIntegerOfMaxValue(_ max: UInt) -> UInt {
		return self.randomUnsignedIntegerInRange(0..<max)
	}
	
	/// Returns an UInt64 value.
	open var randomUnsignedLongLong: UInt64 {
		var value = UInt64(arc4random())
		value <<= 32
		value |= UInt64(arc4random())
		return value
	}
	
}
