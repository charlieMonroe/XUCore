//
//  XUUnfairLock.swift
//  XUCore
//
//  Created by Charlie Monroe on 11/12/19.
//  Copyright © 2019 Charlie Monroe Software. All rights reserved.
//

import Foundation

/// A simple wrapper arount `os_unfair_lock`. This is a class, hence an instance
/// can be passed around and locked without having a mutating context.
@available(macOS 10.12, *)
public final class XUUnfairLock: Lock {
	
	private var _lock: os_unfair_lock = os_unfair_lock()
	
	public init() {
		
	}
	
	public func lock() {
		os_unfair_lock_lock(&_lock)
	}
	
	public func unlock() {
		os_unfair_lock_unlock(&_lock)
	}
	
}
