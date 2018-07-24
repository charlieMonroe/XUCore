//
//  XURandomGenerator.swift
//  XUCore
//
//  Created by Charlie Monroe on 11/5/15.
//  Copyright © 2015 Charlie Monroe Software. All rights reserved.
//

import Foundation

/// Intermediate protocol. Will be removed after Xcode 10 is released with `Random`.
public protocol XURandomGeneratorProtocol {
	func next() -> UInt64
}

#if swift(>=4.2)
extension Random: XURandomGeneratorProtocol {}
#endif

extension XURandomGeneratorProtocol {
	
	/// Returns a random boolean. Does so by getting a random byte and returning
	/// byte % 2 == 0
	public var randomBoolean: Bool {
		return self.randomByte % 2 == 0
	}
	
	/// Returns a random byte.
	public var randomByte: UInt8 {
		return UInt8(self.next() % 256)
	}
	
	
	/// Generates a random Int.
	public func randomInteger() -> Int {
		return self.randomInteger(of: Int.self)
	}
	
	/// Generates a random integer of `type`.
	public func randomInteger<T: FixedWidthInteger>(of type: T.Type) -> T {
		return T(self.next() % UInt64(T.max))
	}
	
	/// Returns an integer in range.
	public func randomInteger<T: FixedWidthInteger>(in range: Range<T>) -> T {
		let count = UInt64(range.upperBound - range.lowerBound)
		return range.lowerBound + T.init(self.next() % count)
	}
	
	/// Returns an integer of max value.
	public func randomInteger<T: FixedWidthInteger>(ofMaximumValue max: T) -> T {
		return self.randomInteger(in: 0 ..< max)
	}
	
	/// Returns a random unsigned integer.
	public var randomUnsignedInteger: UInt {
		return self.randomInteger(of: UInt.self)
	}
	
	/// Returns an unsigned integer in range.
	@available(*, deprecated, renamed: "randomInteger(in:)")
	public func randomUnsignedInteger(in range: Range<UInt>) -> UInt {
		return self.randomInteger(in: range)
	}
	
	/// Returns an unsigned integer of max value.
	@available(*, deprecated, renamed: "randomInteger(ofMaximumValue:)")
	public func randomUnsignedInteger(ofMaximumValue max: UInt) -> UInt {
		return self.randomInteger(ofMaximumValue: max)
	}
}

/// Random number generator based on srandom() - where the seed is set in init
/// to something random
public struct XURandomGenerator: XURandomGeneratorProtocol {

	/// Returns a shared generator.
	public static let shared = XURandomGenerator()
	
	public init() {
		var tv: timeval = timeval(tv_sec: 0, tv_usec: 0)
		gettimeofday(&tv, nil)
		
		srandom(UInt32(((Int(getpid()) << 16) ^ tv.tv_sec ^ Int(tv.tv_usec)) % Int(UInt16.max)))
	}
	
	public func next() -> UInt64 {
		var value = UInt64(arc4random())
		value <<= 32
		value |= UInt64(arc4random())
		return value
	}
	
	/// Returns an UInt64 value.
	@available(*, deprecated, renamed: "next()")
	public var random64BitUnsignedInteger: UInt64 {
		return self.next()
	}
	
}
