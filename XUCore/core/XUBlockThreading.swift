//
//  XUBlockThreading.swift
//  DownieCore
//
//  Created by Charlie Monroe on 10/25/15.
//  Copyright © 2015 Charlie Monroe Software. All rights reserved.
//

import Foundation

/// Performs the block on main thread synchronously. If the current thread already
/// is main thread, the block is performed immediately, preventing dead-lock.
public func XU_PERFORM_BLOCK_ON_MAIN_THREAD(block: () -> Void) {
	if NSThread.isMainThread() {
		block()
	}else{
		dispatch_sync(dispatch_get_main_queue(), block)
	}
}

/// Performs the block on main thread asynchronously. If the current thread already
/// is main thread, the block is performed immediately, preventing dead-lock.
public func XU_PERFORM_BLOCK_ON_MAIN_THREAD_ASYNC(block: () -> Void) {
	if NSThread.isMainThread() {
		block()
	}else{
		dispatch_async(dispatch_get_main_queue(), block)
	}
}

/// Creates a new thread on the default priority queue and executes the block.
public func XU_PERFORM_BLOCK_ASYNC(block: () -> Void) {
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), block)
}
