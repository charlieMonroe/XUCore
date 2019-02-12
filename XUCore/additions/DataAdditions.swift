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
		return c.asciiValue - Character("0").asciiValue
	}

	if c >= Character("a") && c <= Character("f") {
		return (c.asciiValue - Character("a").asciiValue) + 10
	}

	if c >= Character("A") && c <= Character("F") {
		return (c.asciiValue - Character("A").asciiValue) + 10
	}

	return 0
}

public extension Data {
	
	/// Returns a byte at index. Does no bounds checking.
	///
	/// - Parameter index: Index of the byte.
	/// - Returns: Byte at index.
	func byte(at index: Int) -> UInt8 {
		return self.withUnsafeBytes { (ptr: UnsafePointer<UInt8>) -> UInt8 in
			return ptr[index]
		}
	}
	
	/// Returns true if self has a prefix that is defined by the bytes in `prefix`.
	///
	/// - Parameter prefix: Prefix bytes this data is tested against.
	/// - Returns: True if `self` has this prefix.
	func hasPrefix(_ prefix: [UInt8]) -> Bool {
		if self.count < prefix.count {
			return false
		}
		
		return self.withUnsafeBytes { (ptr: UnsafePointer<UInt8>) -> Bool in
			return prefix.enumerated().allSatisfy({ (arg0) -> Bool in
				return ptr[arg0.offset] == arg0.element
			})
			
		}
	}
	
	/// Returns data from a string such as 194736ca92698d0282b76e979f32b17b9b6d.
	init<T: StringProtocol>(hexEncodedString hexString: T) {
		if hexString.count % 2 != 0 {
			self.init()
			return
		}
		
		self.init()
		
		var i = hexString.startIndex
		while i < hexString.endIndex {
			let byte1 = _hexValueOfChar(hexString[i]) << 4
			let byte2 = _hexValueOfChar(hexString[hexString.index(after: i)])
			
			var byte = byte1 | byte2
			self.append(&byte, count: 1)
			
			i = hexString.index(i, offsetBy: 2)
		}
	}
	
	/// Returns `self.bytes` as `Int8` with `filter` applied. If nil is passed as
	/// `filter` (default value of `filter`), all bytes are included.
	func filteredByteArray(using filter: (_ index: Int, _ byte: Int8) -> Bool) -> [Int8] {
		var result: [Int8] = []
		self.withUnsafeBytes { (ptr: UnsafePointer<Int8>) in
			for i in 0 ..< self.count {
				let c = ptr[i]
				if !filter(i, c) {
					continue
				}
				result.append(c)
			}
		}
		
		return result
	}
	
	/// Returns a string such as 194736ca92698d0282b76e979f32b1fa7b9b6d
	var hexEncodedString: String {
		let dataLength = self.count
		if dataLength == 0 {
			return ""
		}
		
		var hexString = ""
		
		self.withUnsafeBytes { (bytes: UnsafePointer<UInt8>) in
			for i in 0 ..< dataLength {
				hexString += String(format: "%02x", bytes[i])
			}
		}
		
		return hexString
	}
	
	func hmacSHA265(with key: Data) -> Data? {
		let cocoaData = (self as NSData)
		return cocoaData.hmacsha256(withKey: key)
	}
	
	func hmacSHA265(with key: String) -> Data? {
		let data = NSData(bytes: (self as NSData).bytes, length: self.count)
		let cocoaKey = NSString(format: "%@", key as NSString)
		return data.hmacsha256(withKey: cocoaKey)
	}
	
	/// Returns first occurrence of bytes within `self`. If it doesn't contain
	/// the data, nil is returned since this method is based on
	/// self.rangeOfData(_:options:range:).
	func indexOfFirstOccurrence(of bytes: UnsafeMutableRawPointer, ofLength length: Int) -> Int? {
		let byteData = Data(bytesNoCopy: bytes, count: length, deallocator: .none)
		return self.range(of: byteData)?.lowerBound
	}
	
	var md5Digest: String {
		return self.withUnsafeBytes({
			return NSData.md5Digest(ofBytes: $0, ofLength: self.count)
		})
	}
	
	/// SHA-1 digest.
	var sha1Digest: String {
		let data = (self as NSData).sha1Digest()
		let bytes = data.map { String(format: "%02x", $0) }
		return bytes.joined()
	}
	
	/// SHA-256 digest.
	var sha256Digest: String {
		let data = (self as NSData).sha256Digest()
		let bytes = data.map { String(format: "%02x", $0) }
		return bytes.joined()
	}
	
	/// SHA-512 digest.
	var sha512Digest: String {
		let data = (self as NSData).sha512Digest()
		let bytes = data.map { String(format: "%02x", $0) }
		return bytes.joined()
	}
	
	/// Reads Int-typed value from stream.
	func readInteger<T: FixedWidthInteger>(startingAtByte index: Int) -> T {
		return self.withUnsafeBytes { (bytes: UnsafePointer<Int8>) -> T in
			let bytes = bytes.advanced(by: index)
			return bytes.withMemoryRebound(to: T.self, capacity: 1, { $0.pointee })
		}
	}
	
	/// Splits the data into chunks of maximum size and returns them as array.
	func splitIntoParts(ofMaximumSize maxSize: Int) -> [Data] {
		if self.count <= maxSize {
			return [self]
		}
		
		return stride(from: 0, to: self.count, by: maxSize).map { index in
			return self.subdata(in: index ..< Swift.min(self.count, index + maxSize))
		}
	}
	
	/// Removes trailing bytes that have value 0.
	var trimmingTrailingZeros: Data {
		let index = self.withUnsafeBytes { (ptr: UnsafePointer<UInt8>) -> Data.Index in
			var index = self.endIndex - 1
			while index >= 0 && ptr[index] == 0 {
				index -= 1
			}
			
			return index + 1
		}
		
		if index == self.endIndex {
			return self
		}
		
		if index == self.startIndex {
			return Data()
		}
		
		return self.subdata(in: 0 ..< index)
	}
	
}
