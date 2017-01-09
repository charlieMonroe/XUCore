//
//  NSLockAdditions.swift
//  XUCore
//
//  Created by Charlie Monroe on 11/8/15.
//  Copyright © 2015 Charlie Monroe Software. All rights reserved.
//

import Foundation

public protocol NamedLock {
	
	var name: String? { get set }
	
	init()
	func lock()
	func unlock()
}

extension NamedLock {
	
	/// Creates a lock and sets the name.
	public init(name: String) {
		self.init()
		
		self.name = name
	}
	
	/// Performs a block while locking itself. It also installs an XUExceptionCatcher
	/// that catches potential ObjC exceptions, which it raises again, but unlocks
	/// self, thus potentially avoiding a deadlock.
	public func perform(locked block: (Void) -> Void) {
		self.lock()
		
		let handler = XUExceptionCatcher(catchHandler: { (exception) -> Void in
			// We only unlock self if an exception was raised. If no exception
			// occurrs, the lock is unlocked within performing the block.
			self.unlock()
			exception.raise() // Rethrow the exception
		}) { /* No-op finally. */ }
		
		handler.perform { () -> Void in
			block()
			self.unlock()
		}
	}
	
}


extension NSLock: NamedLock { }
extension NSRecursiveLock: NamedLock { }
