//
//  SynchronizedProperty.swift
//  XUCore
//
//  Created by Charlie Monroe on 10/15/19.
//  Copyright © 2019 Charlie Monroe Software. All rights reserved.
//

import Foundation

/// A property wrapper that guards access to the property with a lock.
@propertyWrapper
public struct SynchronizedProperty<Value> {
	
	private let _lock: NSLock
	
	private var _wrappedValue: Value
	
	
	/// Creates a new wrapper with `value` and a lock.
	public init(value: Value, lock: NSLock) {
		_lock = lock
		_wrappedValue = value
	}
	
	public var wrappedValue: Value {
		get {
			_lock.lock()
			defer {
				_lock.unlock()
			}
			
			return _wrappedValue
		}
		set {
			_lock.perform {
				_wrappedValue = newValue
			}
		}
	}
	
	
	
}
