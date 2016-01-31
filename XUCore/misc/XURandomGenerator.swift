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
public class XURandomGenerator: NSObject {

	/// Returns a shared generator.
	public static let sharedGenerator = XURandomGenerator()
	
	public override init() {
		super.init()
		
		let str = String()
		let ptr = unsafeAddressOf(str)
		let nullPtr = UnsafePointer<Void>(bitPattern: 0)
		
		/// This gets the address
		let address = nullPtr.distanceTo(ptr)
		
		var tv: timeval = timeval(tv_sec: 0, tv_usec: 0)
		gettimeofday(&tv, nil)
		
		srandom(UInt32(((Int(getpid()) << 16) ^ tv.tv_sec ^ Int(tv.tv_usec) ^ address) % Int(UInt16.max)))
		
	}
	
	/// Returns a random boolean. Does so by getting a random byte and returning
	/// byte % 2 == 0
	public var randomBool: Bool {
		return self.randomByte % 2 == 0
	}
	
	/// Returns a random byte.
	public var randomByte: UInt8 {
		return UInt8(random() % 256)
	}
	
	/// Returns a random unsigned integer.
	public var randomUnsignedInteger: UInt {
		return UInt(random())
	}
	
	/// Returns an unsigned integer in range.
	public func randomUnsignedIntegerInRange(range: Range<UInt>) -> UInt {
		return range.startIndex + (self.randomUnsignedInteger % UInt(range.count))
	}
	
	/// Returns an unsigned integer of max value.
	public func randomUnsignedIntegerOfMaxValue(max: UInt) -> UInt {
		return self.randomUnsignedIntegerInRange(0..<max)
	}
	
	/// Returns an UInt64 value.
	public var randomUnsignedLongLong: UInt64 {
		var value = UInt64(random())
		value <<= 32
		value |= UInt64(random())
		return value
	}
	
}
