//
//  XULockPool.swift
//  XUCore
//
//  Created by Charlie Monroe on 7/27/17.
//  Copyright © 2017 Charlie Monroe Software. All rights reserved.
//

import Foundation

/// A pool of locks. If you have a objects that need to be changed occasionally
/// from different threads, it may not be ideal to create a lock per object -
/// mostly, if there may be a lot of these objects and if the changes are occasional.
///
/// For this, you can use the lock pool which will select a lock for an object
/// out of the pool.
public final class XULockPool {
	
	/// Shared lock pool. Contains 16 locks. If you have more than 256 objects
	/// competing for the pool, consider creating your own larger pool.
	public static let shared: XULockPool = XULockPool(poolSize: 16, name: "XULockPool.shared")
	
	
	/// A lock for modifying the _locks array.
	private let _lockCreatingLock: NSLock
	
	/// Locks - lazily created.
	private var _locks: [NSLock?]
	
	/// Name of the pool. The pool uses this name to name the locks.
	public let name: String
	
	/// Size of the pool.
	public let poolSize: Int
	
	
	
	/// Initializes the pool with a pool size.
	///
	/// - Parameter poolSize: Size of the pool.
	/// - Parameter name: Name of the pool.
	public init(poolSize: Int, name: String) {
		_locks = Array<NSLock?>(repeating: nil, count: poolSize)
		_lockCreatingLock = NSLock(name: name + "_lock_creation")
		
		self.poolSize = poolSize
		self.name = name
	}
	
	
	
	/// Returns a lock for a particular object.
	///
	/// - Parameter object: Object for the lock.
	/// - Returns: Lock associated with the object.
	public func lock(for object: AnyObject) -> NSLock {
		let hash = ObjectIdentifier(object).hashValue
		
		// The hash can be negative -> the index would be negative as well.
		let index = abs(hash % self.poolSize)
		if let lock = _locks[index] {
			return lock
		}
		
		_lockCreatingLock.lock()
		defer {
			_lockCreatingLock.unlock()
		}
		
		// Check if someone else didn't create a lock while we were locking
		// _lockCreatingLock...
		if let lock = _locks[index] {
			return lock
		}
		
		let lock = NSLock(name: self.name + "_\(index)")
		_locks[index] = lock
		return lock
	}
	
	/// Locks a lock associated with the object.
	///
	/// - Parameter object: Object for which to lock.
	public func lock(with object: AnyObject) {
		self.lock(for: object).lock()
	}
	
	/// Performs a locked block. A shortcut for:
	///
	/// 	`self.lock(for: object).perform(locked:)`
	///
	/// - Parameters:
	///   - object: Object for the lock.
	///   - block: Block to be performed.
	public func performLockedBlock(with object: AnyObject, block: () -> Void) {
		self.lock(for: object).perform(locked: block)
	}
	
	/// Unlocks a lock associated with the object.
	///
	/// - Parameter object: Object for which to unlock.
	public func unlock(with object: AnyObject) {
		self.lock(for: object).unlock()
	}
	
}
