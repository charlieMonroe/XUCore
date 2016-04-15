//
//  NSDataAdditions.swift
//  XUCore
//
//  Created by Charlie Monroe on 4/15/16.
//  Copyright © 2016 Charlie Monroe Software. All rights reserved.
//

import Foundation

private func _hexValueOfChar(c: Character) -> Int {
	if c >= Character("0") && c <= Character("9") {
		return Int(c.UTF8Value - Character("0").UTF8Value)
	}

	if c >= Character("a") && c <= Character("f") {
		return Int(c.UTF8Value - Character("a").UTF8Value) + 10
	}

	if c >= Character("A") && c <= Character("F") {
		return Int(c.UTF8Value - Character("A").UTF8Value) + 10
	}

	return 0
}

public extension NSData {

	/// Returns data from a string such as 194736ca92698d0282b76e979f32b17b9b6d.
	public convenience init(hexEncodedString hexString: String) {
		if hexString.characters.count % 2 != 0 {
			self.init()
			return
		}
		
		
		let data = NSMutableData()
		var i = hexString.startIndex
		while i < hexString.endIndex {
			let byte1 = _hexValueOfChar(hexString.characters[i]) << 4
			let byte2 = _hexValueOfChar(hexString.characters[i.successor()])
			
			var byte = (byte1 << 4) | byte2
			data.appendBytes(&byte, length: 1)
			
			i = i.advancedBy(2)
		}
		
		self.init(data: data)
	}
	
	public func byteArrayWithZerosIncluded(includeZeros: Bool) -> [Int8] {
		var result: [Int8] = []
		let bytes = UnsafePointer<Int8>(self.bytes)
		for i in 0 ..< self.length {
			let c = bytes[i]
			if c == 0 && !includeZeros {
				continue
			}
			result.append(c)
		}
		
		return result
	}
	
	/// Returns a string such as 194736ca92698d0282b76e979f32b1fa7b9b6d
	public var hexEncodedString: String {
		let dataLength = self.length
		if dataLength == 0 {
			return ""
		}
		
		let bytes = UnsafePointer<Int8>(self.bytes)
		var hexString = ""
		for i in 0 ..< dataLength {
			hexString += String(format: "%02lx", bytes[i])
		}
		return hexString
	}
	
	public func indexOfFirstOccurrenceOfBytes(bytes: UnsafeMutablePointer<Void>, ofLength length: Int) -> Int {
		return self.rangeOfData(NSData(bytesNoCopy: bytes, length: length, freeWhenDone: false), options: NSDataSearchOptions(), range: NSMakeRange(0, self.length)).location
	}
	
	public var MD5Digest: String {
		return NSData.MD5DigestOfBytes(self.bytes, ofLength: self.length)
	}
	
	public func readIntegerOfLength(length: Int, startingAtIndex index: Int) -> Int {
		assert(length <= sizeof(Int), "This is a way too big of an int!")
		
		var result = 0
		let bytes = UnsafePointer<Int8>(self.bytes)
		
		for i in 0 ..< length {
			let c = Int(bytes[index + i])
			result |= c << (8 * (length - i - 1))
		}
		
		return result
	}

}
