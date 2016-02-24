//
//  NSLockAdditions.swift
//  XUCore
//
//  Created by Charlie Monroe on 11/8/15.
//  Copyright © 2015 Charlie Monroe Software. All rights reserved.
//

import Foundation

public extension NSLock {
	
	/// Creates a lock and sets the name.
	public convenience init(name: String) {
		self.init()
		
		self.name = name
	}
	
	public func performLockedBlock(block: (Void) -> Void) {
		self.lock()
		
		let handler = XUExceptionHandler(catchHandler: { (exception) -> Void in
			// We only unlock self if an exception was raised. If no exception
			// occurrs, the lock is unlocked within performing the block.
			self.unlock()
			exception.raise() // Rethrow the exception
			}) { /* No-op finally. */ }
		
		handler.performBlock { () -> Void in
			block()
			self.unlock()
		}
	}
	
}
