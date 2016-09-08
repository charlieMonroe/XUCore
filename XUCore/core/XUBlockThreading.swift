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
public func XU_PERFORM_BLOCK_ON_MAIN_THREAD(_ block: () -> Void) {
	if Thread.isMainThread {
		block()
	}else{
		DispatchQueue.main.sync(execute: block)
	}
}

/// Performs the block on main thread asynchronously. If the current thread already
/// is main thread, the block is performed immediately, preventing dead-lock.
public func XU_PERFORM_BLOCK_ON_MAIN_THREAD_ASYNC(_ block: @escaping () -> Void) {
	if Thread.isMainThread {
		block()
	}else{
		DispatchQueue.main.async(execute: block)
	}
}

/// Creates a new thread on the default priority queue and executes the block.
public func XU_PERFORM_BLOCK_ASYNC(_ block: @escaping () -> Void) {
	DispatchQueue.global(qos: .default).async(execute: block)
}

/// Dispatches the block after delay on queue. By default, queue is the main queue.
public func XU_PERFORM_DELAYED_BLOCK(_ delay: TimeInterval, queue: DispatchQueue = DispatchQueue.main, block: @escaping () -> Void) {
	queue.asyncAfter(deadline: DispatchTime.now() + Double(Int64(delay * TimeInterval(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: {
		block()
	})

}
