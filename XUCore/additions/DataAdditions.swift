//
//  NSDataAdditions.swift
//  XUCore
//
//  Created by Charlie Monroe on 4/15/16.
//  Copyright © 2016 Charlie Monroe Software. All rights reserved.
//

import Foundation

private func _hexValueOfChar(_ c: Character) -> UInt8 {
	guard let ascii = c.asciiValue else {
		return 0
	}
	
	if c >= Character("0") && c <= Character("9") {
		return ascii - Character("0").asciiValue!
	}

	if c >= Character("a") && c <= Character("f") {
		return (ascii - Character("a").asciiValue!) + 10
	}

	if c >= Character("A") && c <= Character("F") {
		return (ascii - Character("A").asciiValue!) + 10
	}

	return 0
}

extension Data {
	
	/// Returns a byte at index. Does no bounds checking.
	///
	/// - Parameter index: Index of the byte.
	/// - Returns: Byte at index.
	public func byte(at index: Int) -> UInt8 {
		return self.withUnsafeBytes({ (ptr: UnsafeRawBufferPointer) -> UInt8 in
			return ptr.bindMemory(to: UInt8.self)[index]
		})
	}
	
	/// Returns true if it contains subdata. Will return true, if subdata is empty.
	public func contains<D: DataProtocol>(_ subdata: D) -> Bool {
		return self.firstIndex(of: subdata) != nil
	}
	
	public func firstIndex<D: DataProtocol>(of subdata: D) -> Index? {
		if subdata.isEmpty {
			return self.startIndex
		}
		if subdata.count > self.count {
			return nil
		}
		
		guard
			let index = self.firstIndex(of: subdata.first!),
			index + subdata.count <= self.count
		else {
			return nil
		}
		
		for (offset, byte) in subdata.enumerated() {
			guard self[index + offset] == byte else {
				// We know that subdata is not empty, so we can use index + 1.
				return self.suffix(from: index + 1).firstIndex(of: subdata)
			}
		}
		
		return index // We've enumerated all bytes and found the subsequence.
	}
	
	/// Returns true if self has a prefix that is defined by the bytes in `prefix`.
	///
	/// - Parameter prefix: Prefix bytes this data is tested against.
	/// - Returns: True if `self` has this prefix.
	public func hasPrefix(_ prefix: Data) -> Bool {
		if self.count < prefix.count {
			return false
		}
		
		return self.withUnsafeBytes { (ptr: UnsafeRawBufferPointer) -> Bool in
			return prefix.enumerated().allSatisfy({ (arg0) -> Bool in
				return ptr.bindMemory(to: UInt8.self)[arg0.offset] == arg0.element
			})
			
		}
	}
	
	/// Returns true if self has a prefix that is defined by the bytes in `prefix`.
	///
	/// - Parameter prefix: Prefix bytes this data is tested against.
	/// - Returns: True if `self` has this prefix.
	public func hasPrefix(_ prefix: [UInt8]) -> Bool {
		if self.count < prefix.count {
			return false
		}
		
		return self.withUnsafeBytes { (ptr: UnsafeRawBufferPointer) -> Bool in
			return prefix.enumerated().allSatisfy({ (arg0) -> Bool in
				return ptr.bindMemory(to: UInt8.self)[arg0.offset] == arg0.element
			})
			
		}
	}
	
	/// Returns data from a string such as 194736ca92698d0282b76e979f32b17b9b6d.
	public init<T: StringProtocol>(hexEncodedString hexString: T) {
		self.init()
		
		var i = hexString.startIndex
		while i < hexString.endIndex {
			let byte1 = _hexValueOfChar(hexString[i]) << 4
			let byte2: UInt8
			let nextIndex = hexString.index(after: i)
			if nextIndex < hexString.endIndex {
				byte2 = _hexValueOfChar(hexString[nextIndex])
			} else {
				byte2 = 0
			}
			
			var byte = byte1 | byte2
			self.append(&byte, count: 1)
			
			i = hexString.index(i, offsetBy: 2)
		}
	}
	
	/// Returns `self.bytes` as `Int8` with `filter` applied. If nil is passed as
	/// `filter` (default value of `filter`), all bytes are included.
	public func filteredByteArray(using filter: (_ index: Int, _ byte: Int8) -> Bool) -> [Int8] {
		var result: [Int8] = []
		self.withUnsafeBytes { (rawPointer: UnsafeRawBufferPointer) in
			let ptr = rawPointer.bindMemory(to: Int8.self)
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
	public var hexEncodedString: String {
		let dataLength = self.count
		if dataLength == 0 {
			return ""
		}
		
		var hexString = ""
		
		self.withUnsafeBytes { (rawPointer: UnsafeRawBufferPointer) in
			let bytes = rawPointer.bindMemory(to: UInt8.self)
			for i in 0 ..< dataLength {
				hexString += String(format: "%02x", bytes[i])
			}
		}
		
		return hexString
	}
	
	/// Returns first occurrence of bytes within `self`. If it doesn't contain
	/// the data, nil is returned since this method is based on
	/// self.rangeOfData(_:options:range:).
	public func indexOfFirstOccurrence(of bytes: UnsafeMutableRawPointer, ofLength length: Int) -> Int? {
		let byteData = Data(bytesNoCopy: bytes, count: length, deallocator: .none)
		return self.range(of: byteData)?.lowerBound
	}
	
	/// Reads Int-typed value from stream.
	public func readInteger<T: FixedWidthInteger>(startingAtByte index: Int) -> T {
		// If we don't make subdata, we'll get a read from non-aligned pointer.
		let subdata = self.subdata(in: index ..< index + T.bitWidth / 8)
		return subdata.withUnsafeBytes { (rawBytes: UnsafeRawBufferPointer) -> T in
			return rawBytes.bindMemory(to: T.self)[0]
		}
	}
	
	/// Splits the data into chunks of maximum size and returns them as array.
	public func splitIntoParts(ofMaximumSize maxSize: Int) -> [Data] {
		if self.count <= maxSize {
			return [self]
		}
		
		return stride(from: 0, to: self.count, by: maxSize).map { index in
			return self.subdata(in: index ..< Swift.min(self.count, index + maxSize))
		}
	}
	
	/// Removes trailing bytes that have value 0.
	public var trimmingTrailingZeros: Data {
		let index = self.withUnsafeBytes { (rawPointer: UnsafeRawBufferPointer) -> Data.Index in
			let ptr = rawPointer.bindMemory(to: UInt8.self)
			
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
