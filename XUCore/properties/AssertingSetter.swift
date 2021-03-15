//
//  AssertingSetter.swift
//  XUCore
//
//  Created by Charlie Monroe on 1/27/21.
//  Copyright © 2021 Charlie Monroe Software. All rights reserved.
//

import Foundation

@propertyWrapper
public struct AssertingSetter<T> {
	
	@propertyWrapper
	public struct MainThread {
		
		public init(wrappedValue: T) {
			self.wrappedValue = wrappedValue
		}
		
		public var wrappedValue: T {
			didSet {
				XUAssert(Thread.isMainThread)
			}
		}
		
	}
	
	/// An assertion. The value that was set is passed to the assertion.
	public let assertion: (T) -> Bool
	
	public init(assertion: @escaping (T) -> Bool, wrappedValue: T) {
		self.assertion = assertion
		self.wrappedValue = wrappedValue
	}
		
	public var wrappedValue: T {
		didSet {
			XUAssert(self.assertion(self.wrappedValue))
		}
	}
	
}
