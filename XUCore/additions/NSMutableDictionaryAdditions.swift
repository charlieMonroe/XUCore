//
//  NSMutableDictionaryAdditions.swift
//  XUCore
//
//  Created by Charlie Monroe on 11/11/15.
//  Copyright © 2015 Charlie Monroe Software. All rights reserved.
//

import Foundation

public extension NSMutableDictionary {
	
	public func setBool(aBool: Bool, forKey key: Key) {
		self[key] = aBool
	}
	public func setFloat(aFloat: Float, forKey key: Key) {
		self[key] = aFloat
	}
	public func setInt(anInt: Int32, forKey key: Key) {
		self[key] = NSNumber(int: anInt)
	}
	public func setUnsignedInt(anInt: UInt32, forKey key: Key) {
		self[key] = NSNumber(unsignedInt: anInt)
	}
	public func setUnsignedShort(aShort: UInt16, forKey key: Key) {
		self[key] = NSNumber(unsignedShort: aShort)
	}
	public func setObjectConditionally(object: AnyObject?, forKey key: Key) -> Bool {
		if object != nil {
			self[key] = object!
			return true
		}
		return false
	}
	
}


