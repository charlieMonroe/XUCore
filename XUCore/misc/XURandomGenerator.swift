//
//  XURandomGenerator.swift
//  XUCore
//
//  Created by Charlie Monroe on 11/5/15.
//  Copyright © 2015 Charlie Monroe Software. All rights reserved.
//

import Foundation

/// Intermediate protocol. Will be removed after Xcode 10 is released with `SystemRandomNumberGenerator`.
public protocol XURandomGeneratorProtocol {
	mutating func next() -> UInt64
}

#if swift(>=4.2)
extension SystemRandomNumberGenerator: XURandomGeneratorProtocol {}
#endif

extension XURandomGeneratorProtocol {
	
	/// Returns a random boolean. Does so by getting a random byte and returning
	/// byte % 2 == 0
	public var randomBoolean: Bool { mutating get {
		return self.randomByte % 2 == 0
	}}
	
	/// Returns a random byte.
	public var randomByte: UInt8 { mutating get {
		return UInt8(self.next() % 256)
	}}
	
	
	/// Generates a random Int.
	public mutating func randomInteger() -> Int {
		return self.randomInteger(of: Int.self)
	}
	
	/// Generates a random integer of `type`.
	public mutating func randomInteger<T: FixedWidthInteger>(of type: T.Type) -> T {
		return T(self.next() % UInt64(T.max))
	}
	
	/// Returns an integer in range.
	public mutating func randomInteger<T: FixedWidthInteger>(in range: Range<T>) -> T {
		let count = UInt64(range.upperBound - range.lowerBound)
		return range.lowerBound + T.init(self.next() % count)
	}
	
	/// Returns an integer of max value.
	public mutating func randomInteger<T: FixedWidthInteger>(ofMaximumValue max: T) -> T {
		return self.randomInteger(in: 0 ..< max)
	}
	
	/// Returns a random unsigned integer.
	public var randomUnsignedInteger: UInt { mutating get {
		return self.randomInteger(of: UInt.self)
	}}
	
}

/// Random number generator based on srandom() - where the seed is set in init
/// to something random
public struct XURandomGenerator: XURandomGeneratorProtocol {

	/// Returns a shared generator.
	public static var shared = XURandomGenerator()
	
	public init() {
		var tv: timeval = timeval(tv_sec: 0, tv_usec: 0)
		gettimeofday(&tv, nil)
		
		srandom(UInt32(((Int(getpid()) << 16) ^ tv.tv_sec ^ Int(tv.tv_usec)) % Int(UInt16.max)))
	}
	
	public mutating func next() -> UInt64 {
		var value = UInt64(arc4random())
		value <<= 32
		value |= UInt64(arc4random())
		return value
	}
	
}
