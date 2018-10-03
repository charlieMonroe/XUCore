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
@available(*, deprecated, renamed: "DispatchQueue.main.syncOrNow(execute:)")
public func XU_PERFORM_BLOCK_ON_MAIN_THREAD(_ block: () -> Void) {
	if Thread.isMainThread {
		block()
	} else {
		DispatchQueue.main.sync(execute: block)
	}
}

/// Performs the block on main thread asynchronously. If the current thread already
/// is main thread, the block is performed immediately, preventing dead-lock.
public func XU_PERFORM_BLOCK_ON_MAIN_THREAD_ASYNC(_ block: @escaping () -> Void) {
	if Thread.isMainThread {
		block()
	} else {
		DispatchQueue.main.async(execute: block)
	}
}

/// Creates a new thread on the default priority queue and executes the block.
@available(*, deprecated, message: "Use DispatchQueue.global(qos: .default).async(execute:)")
public func XU_PERFORM_BLOCK_ASYNC(_ block: @escaping () -> Void) {
	DispatchQueue.global(qos: .default).async(execute: block)
}

/// Dispatches the block after delay on queue. By default, queue is the main queue.
@available(*, deprecated, message: "Use queue.asyncAfter(.seconds((qos: .default).async(execute:)")
public func XU_PERFORM_DELAYED_BLOCK(_ delay: TimeInterval, queue: DispatchQueue = DispatchQueue.main, block: @escaping () -> Void) {
	queue.asyncAfter(deadline: DispatchTime.now() + Double(Int64(delay * TimeInterval(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: {
		block()
	})

}

extension DispatchTime {
	
	/// Returns DispatchTime in seconds.
	public static func seconds(_ seconds: TimeInterval) -> DispatchTime {
		return DispatchTime.now() + Double(Int64(seconds * TimeInterval(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
	}
	
}

extension DispatchQueue {
	
	/// Performs the closure synchronously or now in case the current thread is
	/// main and it is called on a main thread. This prevents deadlocks.
	public func syncOrNow(execute closure: () -> Void) {
		if Thread.isMainThread && self == .main {
			closure()
		} else {
			self.sync(execute: closure)
		}
	}
	
}

/// A simple class that allows you to perform a block on main thread via the old
/// ObjC thread-based API. This can be useful for various operations done asynchronously
/// within a modal dialog.
public final class XUThreadPerformer: NSObject {

	/// Action to be performed.
	public let action: () -> Void
	
	
	@objc private func _invokeAction() {
		self.action()
	}
	
	public init(action: @escaping () -> Void) {
		self.action = action
	}
	
	public func perform(on thread: Thread) {
		self.perform(#selector(_invokeAction), on: thread, with: nil, waitUntilDone: true, modes: [RunLoop.Mode.common.rawValue])
	}
	
}

