//
//  XUBlockThreading.swift
//  DownieCore
//
//  Created by Charlie Monroe on 10/25/15.
//  Copyright © 2015 Charlie Monroe Software. All rights reserved.
//

import Foundation

extension DispatchTime {
	
	/// Returns DispatchTime in seconds.
	public static func seconds(_ seconds: TimeInterval) -> DispatchTime {
		return DispatchTime.now() + Double(Int64(seconds * TimeInterval(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
	}
	
}

extension DispatchQueue {
	
	/// Performs the closure synchronously or now in case the current thread is
	/// main and it is called on a main thread. This prevents deadlocks.
	public static func onMain<T: Sendable>(execute closure: @MainActor () -> T) -> T {
		if Thread.isMainThread {
			return MainActor.assumeIsolated(closure)
		} else {
			return DispatchQueue.main.sync(execute: closure)
		}
	}
	
	/// Performs the closure synchronously or now in case the current thread is
	/// main and it is called on a main thread. This prevents deadlocks.
	///
	/// Deprecated.
	@available(*, deprecated, renamed: "onMain")
	public func syncOrNow<T>(execute closure: () -> T) -> T {
		DispatchQueue.onMain(execute: closure)
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

