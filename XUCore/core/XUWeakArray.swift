//
//  XUWeakArray.swift
//  XUCore
//
//  Created by Charlie Monroe on 7/27/16.
//  Copyright © 2016 Charlie Monroe Software. All rights reserved.
//

import Foundation

/// A class that contains a weak reference to an object. Useful for array and
/// dictionary entries.
public final class XUWeakReference<T: AnyObject> {
	
	/// Weak reference.
	public weak var objectValue: T?
	
	/// Designated initializer.
	public init(objectValue: T?) {
		self.objectValue = objectValue
	}
}

public struct XUWeakArray<T: AnyObject>: Sequence {
	
	typealias GeneratorType = XUWeakArrayGenerator<T>

	private var _innerArray: [XUWeakReference<T>] = []
	
	public mutating func append(_ value: T?) {
		_innerArray.append(XUWeakReference(objectValue: value))
	}
	
	/// Gathers all non-nil values into an array.
	public var allValues: [T] {
		return _innerArray.flatMap({ $0.objectValue })
	}
	
	/// Returns whether the array contains the object. The comparison is pointer
	/// based.
	public func contains(_ obj: T) -> Bool {
		return _innerArray.contains(where: { $0.objectValue === obj })
	}
	
	/// Number of items. Unlike .isEmpty, this does not count number of items.
	/// It currently breaks the axiom self.isEmpty <=> self.count == 0. Use 
	/// self.numberOfNonnilValues instead.
	public var count: Int {
		return _innerArray.count
	}
	
	/// This variable is not O(1), but O(n) at worst. It goes through the array
	/// of weak references and actually checks them for nil. As soon as it hits
	/// a nonnil value, however, it will return false. The worst O(n) scenario
	/// happens when the array is full of nil values and performCleanup() was not
	/// called.
	public var isEmpty: Bool {
		return !_innerArray.contains(where: { $0.objectValue != nil })
	}
	
	/// Returns the first item in the list, not checking for nil.
	public var first: T? {
		return _innerArray.first?.objectValue
	}
	
	/// Returns index of an object. The equality is always considered pointer-wise.
	public func index(of obj: T) -> Int? {
		return _innerArray.index(where: { $0.objectValue === obj })
	}
	
	/// Returns the last item in the list, not checking for nil.
	public var last: T? {
		return _innerArray.last?.objectValue
	}
	
	public func makeIterator() -> XUWeakArrayGenerator<T> {
		return XUWeakArrayGenerator(slice: _innerArray.map({ $0.objectValue }).slice(with: 0 ..< _innerArray.count))
	}
	
	/// Returns number of nonnil values by going through the inner array. Always
	/// O(n).
	public var numberOfNonNilValues: Int {
		return _innerArray.count(where: { $0.objectValue != nil })
	}
	
	/// Removes all nil values from the array.
	public mutating func performCleanup() {
		for i in (0 ..< self.count).reversed() {
			if _innerArray[i].objectValue == nil {
				_innerArray.remove(at: i)
			}
		}
	}
	
	/// Removes an item at index.
	public mutating func remove(atIndex index: Int) {
		_innerArray.remove(at: index)
	}
	
	public subscript(index: Int) -> T? {
		get {
			return _innerArray[index].objectValue
		}
		set {
			_innerArray[index] = XUWeakReference(objectValue: newValue)
		}
	}
	
	public init() {
		// No-op
	}
	
	/// Initialize with values.
	public init(values: [T]) {
		_innerArray = values.map({ XUWeakReference(objectValue: $0) })
	}
	
}

public struct XUWeakArrayGenerator<T: AnyObject>: IteratorProtocol {
	
	public typealias Element = T
	
	private var _items: ArraySlice<T?>
	
	mutating public func next() -> T? {
		while !_items.isEmpty {
			let next = _items[0]
			_items = _items.dropFirst()
			if next != nil {
				return next
			}
		}
		return nil
	}
	
	fileprivate init(slice: ArraySlice<T?>) {
		self._items = slice
	}

}
