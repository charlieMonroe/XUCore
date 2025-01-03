//
//  NSLockAdditions.swift
//  XUCore
//
//  Created by Charlie Monroe on 11/8/15.
//  Copyright © 2015 Charlie Monroe Software. All rights reserved.
//

import Foundation

public protocol Lock {
	init()
	func lock()
	func unlock()
}


extension Lock {

	/// Performs a block while locking itself. It also installs an XUExceptionCatcher
	/// that catches potential ObjC exceptions, which it raises again, but unlocks
	/// self, thus potentially avoiding a deadlock.
	public func perform<T>(locked block: () -> T) -> T {
		self.lock()
		
		var returnValue: T? = nil
		XUExceptionCatcher.perform({
			returnValue = block()
			self.unlock()
		}, withCatchHandler: { (exception) -> Void in
			// We only unlock self if an exception was raised. If no exception
			// occurs, the lock is unlocked within performing the block.
			self.unlock()
			exception.raise() // Rethrow the exception
		})
		
		return returnValue!
	}
	
	/// Performs a block while locking itself. It also installs an XUExceptionCatcher
	/// that catches potential ObjC exceptions, which it raises again, but unlocks
	/// self, thus potentially avoiding a deadlock.
	public func perform<T>(locked block: () throws -> T) throws -> T {
		self.lock()
		
		var returnValue: T? = nil
		var thrownError: Error?
		XUExceptionCatcher.perform({
			do {
				returnValue = try block()
			} catch {
				thrownError = error
			}
			self.unlock()
		}, withCatchHandler: { (exception) -> Void in
			// We only unlock self if an exception was raised. If no exception
			// occurs, the lock is unlocked within performing the block.
			self.unlock()
			exception.raise() // Rethrow the exception
		})
		
		if let thrownError = thrownError {
			throw thrownError
		}
		
		return returnValue!
	}
	
}

@propertyWrapper
public struct LockedAccessProperty<T> {
	
	private var _wrappedValue: T
	
	public let lock: Lock
	
	public init(wrappedValue: T, lock: Lock) {
		_wrappedValue = wrappedValue
		
		self.lock = lock
	}
    
	public var wrappedValue: T {
		get {
			self.lock.perform {
				_wrappedValue
			}
		}
		set {
			self.lock.perform {
				_wrappedValue = newValue
			}
		}
	}
	
}

public protocol NamedLock: Lock {
	
	var name: String? { get set }
	
}

extension NamedLock {
	
	/// Creates a lock and sets the name.
	public init(name: String) {
		self.init()
		
		self.name = name
	}
		
}


extension NSLock: NamedLock { }
extension NSRecursiveLock: NamedLock { }
