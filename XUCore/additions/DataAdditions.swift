//
//  NSDataAdditions.swift
//  XUCore
//
//  Created by Charlie Monroe on 4/15/16.
//  Copyright © 2016 Charlie Monroe Software. All rights reserved.
//

import Foundation

private func _hexValueOfChar(_ c: Character) -> UInt8 {
	if c >= Character("0") && c <= Character("9") {
		return c.UTF8Value - Character("0").UTF8Value
	}

	if c >= Character("a") && c <= Character("f") {
		return (c.UTF8Value - Character("a").UTF8Value) + 10
	}

	if c >= Character("A") && c <= Character("F") {
		return (c.UTF8Value - Character("A").UTF8Value) + 10
	}

	return 0
}

public extension Data {
	
	/// Returns data from a string such as 194736ca92698d0282b76e979f32b17b9b6d.
	public init(hexEncodedString hexString: String) {
		if hexString.characters.count % 2 != 0 {
			self.init()
			return
		}
		
		self.init()
		
		var i = hexString.startIndex
		while i < hexString.endIndex {
			let byte1 = _hexValueOfChar(hexString.characters[i]) << 4
			let byte2 = _hexValueOfChar(hexString.characters[hexString.characters.index(after: i)])
			
			var byte = byte1 | byte2
			self.append(&byte, count: 1)
			
			i = hexString.characters.index(i, offsetBy: 2)
		}
	}
	
	/// Returns `self.bytes` as `Int8` with `filter` applied. If nil is passed as
	/// `filter` (default value of `filter`), all bytes are included.
	public func filteredByteArray(_ filter: ((_ index: Int, _ byte: Int8) -> Bool)! = nil) -> [Int8] {
		var result: [Int8] = []
		let bytes = (self as NSData).bytes.bindMemory(to: Int8.self, capacity: self.count)
		for i in 0 ..< self.count {
			let c = bytes[i]
			if filter != nil && !filter(i, c) {
				continue
			}
			result.append(c)
		}
		
		return result
	}
	
	/// Returns a string such as 194736ca92698d0282b76e979f32b1fa7b9b6d
	public var hexEncodedString: String {
		let dataLength = self.count
		if dataLength == 0 {
			return ""
		}
		
		let bytes = (self as NSData).bytes.bindMemory(to: UInt8.self, capacity: self.count)
		var hexString = ""
		for i in 0 ..< dataLength {
			hexString += String(format: "%02x", bytes[i])
		}
		return hexString
	}
	
	/// Returns first occurrence of bytes within `self`. If it doesn't contain
	/// the data, nil is returned since this method is based on
	/// self.rangeOfData(_:options:range:).
	public func indexOfFirstOccurrenceOfBytes(_ bytes: UnsafeMutableRawPointer, ofLength length: Int) -> Int? {
		let byteData = Data(bytesNoCopy: bytes, count: length, deallocator: .none)
		return self.range(of: byteData)?.lowerBound
	}
	
	public var md5Digest: String {
		return NSData.md5Digest(ofBytes: (self as NSData).bytes, ofLength: self.count)
	}
	
	public var sha512Digest: String {
		let data = (self as NSData).sha512Digest()
		let bytes = data.map { String(format: "%02x", $0) }
		return bytes.joined()
	}
	
	/// Reads Int-typed value from stream.
	public func readInteger<T: Integer>(startingAtByte index: Int) -> T {
		return self.withUnsafeBytes { (bytes: UnsafePointer<Int8>) -> T in
			let bytes = bytes.advanced(by: index)
			return bytes.withMemoryRebound(to: T.self, capacity: 1, { $0.pointee })
		}
	}
	
}
