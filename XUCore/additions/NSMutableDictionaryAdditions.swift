//
//  NSMutableDictionaryAdditions.swift
//  XUCore
//
//  Created by Charlie Monroe on 11/11/15.
//  Copyright © 2015 Charlie Monroe Software. All rights reserved.
//

import Foundation

public extension NSMutableDictionary {
	
	public func setBool(_ aBool: Bool, forKey key: Key) {
		self[key] = aBool
	}
	public func setFloat(_ aFloat: Float, forKey key: Key) {
		self[key] = aFloat
	}
	public func setInt(_ anInt: Int32, forKey key: Key) {
		self[key] = NSNumber(value: anInt as Int32)
	}
	public func setUnsignedInt(_ anInt: UInt32, forKey key: Key) {
		self[key] = NSNumber(value: anInt as UInt32)
	}
	public func setUnsignedShort(_ aShort: UInt16, forKey key: Key) {
		self[key] = NSNumber(value: aShort as UInt16)
	}
	public func setObjectConditionally(_ object: AnyObject?, forKey key: Key) -> Bool {
		if object != nil {
			self[key] = object!
			return true
		}
		return false
	}
	
}


