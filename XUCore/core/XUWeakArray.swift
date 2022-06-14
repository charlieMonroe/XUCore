//
//  XUWeakArray.swift
//  XUCore
//
//  Created by Charlie Monroe on 7/27/16.
//  Copyright © 2016 Charlie Monroe Software. All rights reserved.
//

import Foundation

/// A structure that will use either strong or weak reference, depending on the system version
/// running.
///
/// This is used e.g. for URLSessionDownloadTask which is retained on macOS 12 or earlier,
/// but not retained on macOS 13, causing crashes due to the task being deallocated.
public struct ConditionalWeakReference<T: AnyObject> {
	
	var strongReference: T!
	
	weak var weakReference: T!
	
	/// Returns the object - either the strong or weak reference.
	public var object: T! {
		if let strongReference = self.strongReference {
			return strongReference
		}
		return self.weakReference
	}
	
	/// Creates a new wrapper that will will use strong reference on macOS versions later than
	/// `version`.
	public init(object: T, requiresStrongReferenceSince version: OperatingSystemVersion) {
		if ProcessInfo().isOperatingSystemAtLeast(version) {
			self.strongReference = object
			self.weakReference = nil
		} else {
			self.strongReference = nil
			self.weakReference = object
		}
	}
	
	/// Creates a new wrapper that will will use weak reference on macOS versions later than
	/// `version`.
	public init(object: T, requiresWeakReferenceSince version: OperatingSystemVersion) {
		if ProcessInfo().isOperatingSystemAtLeast(version) {
			self.strongReference = nil
			self.weakReference = object
		} else {
			self.strongReference = object
			self.weakReference = nil
		}
	}
	
}

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

public struct XUWeakArray<Element: AnyObject>: Sequence {
	
	typealias GeneratorType = XUWeakArrayGenerator<Element>

	private var _innerArray: [XUWeakReference<Element>] = []
	
	public mutating func append(_ value: Element?) {
		_innerArray.append(XUWeakReference(objectValue: value))
	}
	
	/// Gathers all non-nil values into an array.
	public var allValues: [Element] {
		return _innerArray.compactMap({ $0.objectValue })
	}
	
	/// Returns whether the array contains the object. The comparison is pointer
	/// based.
	public func contains(_ obj: Element) -> Bool {
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
	public var first: Element? {
		return _innerArray.first?.objectValue
	}
	
	/// Returns index of an object. The equality is always considered pointer-wise.
	public func index(of obj: Element) -> Int? {
		return _innerArray.firstIndex(where: { $0.objectValue === obj })
	}
	
	/// Returns the last item in the list, not checking for nil.
	public var last: Element? {
		return _innerArray.last?.objectValue
	}
	
	public func makeIterator() -> XUWeakArrayGenerator<Element> {
		return XUWeakArrayGenerator(items: _innerArray.map({ $0.objectValue }))
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
	
	public subscript(index: Int) -> Element? {
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
	public init(values: [Element]) {
		_innerArray = values.map(XUWeakReference.init(objectValue:))
	}
	
}

public struct XUWeakArrayGenerator<Element: AnyObject>: IteratorProtocol {
	
	private var _index: Int = 0
	private var _items: [Element?]
	
	mutating public func next() -> Element? {
		while _index < _items.count {
			let next = _items[_index]
			_index += 1
			
			if next != nil {
				return next
			}
		}
		return nil
	}
	
	fileprivate init(items: [Element?]) {
		self._items = items
	}

}
