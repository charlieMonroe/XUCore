//
//  NSInputStream+Reading.swift
//  DownieCore
//
//  Created by Charlie Monroe on 10/26/15.
//  Copyright © 2015 Charlie Monroe Software. All rights reserved.
//

import Foundation

public extension InputStream {
	
	/// Reads Int-typed value from stream.
	public func read<T : Integer>() -> T? {
		var buffer: T = 0
		let n = withUnsafePointer(to: &buffer) { (p) in
			p.withMemoryRebound(to: UInt8.self, capacity: MemoryLayout<T>.size, { (ptr) -> Int in
				self.read(ptr, maxLength: MemoryLayout<T>.size)
			})
		}
		
		if n > 0 {
			assert(n == MemoryLayout<T>.size, "read length must be sizeof(T)")
			return buffer
		} else {
			return nil
		}
	}
	
}
