//
//  NSLockAdditions.swift
//  XUCore
//
//  Created by Charlie Monroe on 11/8/15.
//  Copyright © 2015 Charlie Monroe Software. All rights reserved.
//

import Foundation

public extension NSLock {
	
	public func performLockedBlock(block: (Void) -> Void) {
		self.lock()
		block()
		self.unlock()
	}
	
}
