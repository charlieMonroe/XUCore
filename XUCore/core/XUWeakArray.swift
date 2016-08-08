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

public struct XUWeakArray<T: AnyObject>: SequenceType {
	
	typealias GeneratorType = XUWeakArrayGenerator<T>

	private var _innerArray: [XUWeakReference<T>] = []
	
	public mutating func append(value: T?) {
		_innerArray.append(XUWeakReference(objectValue: value))
	}
	
	public var count: Int {
		return _innerArray.count
	}
	public var isEmpty: Bool {
		return _innerArray.isEmpty
	}
	public var first: T? {
		return self[0]
	}
	
	public func generate() -> XUWeakArrayGenerator<T> {
		return XUWeakArrayGenerator(slice: _innerArray.map({ $0.objectValue }).sliceWithRange(0 ..< _innerArray.count))
	}
	
	public var last: T? {
		return self[self.count - 1]
	}
	
	public mutating func remove(atIndex index: Int) {
		_innerArray.removeAtIndex(index)
	}
	
	subscript(index: Int) -> T? {
		get {
			return _innerArray[index].objectValue
		}
		set {
			_innerArray[index] = XUWeakReference(objectValue: newValue)
		}
	}
	
}

public struct XUWeakArrayGenerator<T: AnyObject>: GeneratorType {
	
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
	
	private init(slice: ArraySlice<T?>) {
		self._items = slice
	}

}
