//
//  XUObjectPool.swift
//  XUCore
//
//  Created by Charlie Monroe on 7/25/19.
//  Copyright © 2019 Charlie Monroe Software. All rights reserved.
//

import Foundation


/// A protocol that defines one single requirement - an argument-less initializer.
public protocol XUInitializable: AnyObject {
	
	init()
	
}


/// An object pool. This pool recycles objects and creates new ones. The usage
/// is as follows:
///
/// let obj = pool.get()
/// ...
///
/// Once done, call pool.retire(obj).
///
/// Note that this class is not thread safe.
public final class XUObjectPool<T: AnyObject & Hashable> {
	
	public struct Constants {
		
		/// Default pool capacity.
		public static var defaultCapacity: Int {
			return 16
		}
		
	}
	
	
	/// Objects that are ready to be reused.
	private var _retiredObjects: Set<T> = Set()
	
	/// Objects that are currently in use.
	private var _trackedObjects: Set<T> = Set()
	
	
	/// Capacity of the pool.
	public let capacity: Int
	
	/// Function that creates new objects.
	public let initializer: () -> T
	
	/// Function that gets called when an object is about to be reused.
	public let reuseCallback: (T) -> Void
	
	
	/// Returns a new object. If there is a retired object, one is returned after
	/// reuseCallback is called which allows you to re-initialize the object.
	/// If there isn't one, new one is created using self.initializer. Note that
	/// the capacity isn't taken into account and new object is created even if
	/// we're over capacity.
	public func get() -> T {
		if let first = _retiredObjects.first {
			_retiredObjects.remove(first)
			_trackedObjects.insert(first)
			
			self.reuseCallback(first)
			return first
		}
		
		let obj = self.initializer()
		_trackedObjects.insert(obj)
		return obj
	}
	
	public init(capacity: Int = Constants.defaultCapacity, initializer: @escaping () -> T, reuseCallback: @escaping (T) -> Void = { _ in }) {
		self.capacity = capacity
		self.initializer = initializer
		self.reuseCallback = reuseCallback
	}
	
	/// Prints some basic statistics into the console.
	public func printStatistics() {
		XULog("Object pool of \(T.self):")
		XULog("Capacity: \(self.capacity)")
		XULog("Retired Object Count: \(_retiredObjects.count)")
		XULog("Tracked Object Count: \(_trackedObjects.count)")
	}
	
	/// Retires an object. If the capacity for retired objects is full, the object
	/// is immmediately released.
	///
	/// Asserts that the object was created by this pool.
	public func retire(_ object: T) {
		assert(_trackedObjects.contains(object))
		
		_trackedObjects.remove(object)
		
		if _retiredObjects.count < self.capacity {
			_retiredObjects.insert(object)
		}
	}
	
}

extension XUObjectPool where T: XUInitializable {
	
	/// If the object is XUInitializable, we don't need the initializer as it already
	/// exists - the class' init() method.
	public convenience init(capacity: Int = Constants.defaultCapacity, reuseCallback: @escaping (T) -> Void = { _ in }) {
		self.init(capacity: capacity, initializer: T.init, reuseCallback: reuseCallback)
	}
	
}
