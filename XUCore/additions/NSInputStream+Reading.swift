//
//  NSInputStream+Reading.swift
//  DownieCore
//
//  Created by Charlie Monroe on 10/26/15.
//  Copyright © 2015 Charlie Monroe Software. All rights reserved.
//

import Foundation

public extension NSInputStream {
	
	/// Reads Int-typed value from stream.
	public func read<T : IntegerType>() -> T? {
		var buffer : T = 0
		let n = withUnsafePointer(&buffer) { (p) in
			self.read(UnsafeMutablePointer(p), maxLength: sizeof(T))
		}
		
		if n > 0 {
			assert(n == sizeof(T), "read length must be sizeof(T)")
			return buffer
		} else {
			return nil
		}
	}
	
}
