//
//  ArrayExtensions.swift
//  DownieCore
//
//  Created by Charlie Monroe on 5/12/15.
//  Copyright (c) 2015 Charlie Monroe Software. All rights reserved.
//

import Foundation

fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


public extension Sequence {
	
	public typealias Filter = (Self.Iterator.Element) -> Bool
	
	/// Returns true if all of the elements in self match the filter
	public func all(matching filter: Filter) -> Bool {
		return self.find(where: { !filter($0) }) == nil
	}
	
	/// Counts elements that match the filter
	public func count(where filter: XUFilter) -> Int {
		let count =  self.sum({ (obj) -> Int in
			return filter(obj) ? 1 : 0
		})
		return count
	}
	
	/// Returns the first element in self that matches the filter
	public func find(where filter: Filter) -> Self.Iterator.Element? {
		for obj in self {
			if filter(obj) {
				return obj
			}
		}
		return nil
	}
	
	/// Finds a mapped value. When `filter` returns a non-nil value, that value
	/// is returned. This way you can do some computation in the block and return
	/// the value without the need of doing the computation again
	public func findMapped<U>(_ filter: (Self.Iterator.Element) -> U?) -> U? {
		for obj in self {
			let val = filter(obj)
			if val != nil {
				return val
			}
		}
		return nil
	}
	
	/// Finds a maximum value within self. For non-empty arrays, always returns
	/// a non-nil value.
	public func findMax<T: Comparable>(_ valuator: (Self.Iterator.Element) -> T) -> Self.Iterator.Element? {
		var maxElement: Self.Iterator.Element? = nil
		var maxValue: T! = nil
		
		for obj in self {
			let value = valuator(obj)
			if maxElement == nil || value > maxValue {
				maxValue = value
				maxElement = obj
			}
		}
		
		return maxElement
	}
	
	/// This will return the maximum value returned by the valuator, or nil if the
	/// array is empty.
	public func findMaxValue<T: Comparable>(_ valuator: (Self.Iterator.Element) -> T) -> T? {
		var maxValue: T? = nil
		
		for obj in self {
			let value = valuator(obj)
			if maxValue == nil || value > maxValue! {
				maxValue = value
			}
		}
		
		return maxValue
	}
	
	/// Finds a minimum value within self. For non-empty arrays, always returns
	/// a non-nil value.
	public func findMin<T: Comparable>(_ valuator: (Self.Iterator.Element) -> T) -> Self.Iterator.Element? {
		var minElement: Self.Iterator.Element? = nil
		var minValue: T! = nil
		
		for obj in self {
			let value = valuator(obj)
			if minElement == nil || value < minValue {
				minValue = value
				minElement = obj
			}
		}
		
		return minElement
	}
	
	/// This will return the minimum value returned by the valuator, or nil if the
	/// array is empty.
	public func findMinValue<T: Comparable>(_ valuator: (Self.Iterator.Element) -> T) -> T? {
		var minValue: T? = nil
		
		for obj in self {
			let value = valuator(obj)
			if minValue == nil || value < minValue! {
				minValue = value
			}
		}
		
		return minValue
	}
	
	/// Returns a new array by removing objects that match the filter
	public func removing(matching filter: Filter) -> [Self.Iterator.Element] {
		var arr: [Self.Iterator.Element] = [ ]
		for obj in self {
			if !filter(obj) {
				arr.append(obj)
			}
		}
		return arr
	}
	
	/// Sums up values of elements in self.
	public func sum<T: SignedInteger>(_ numerator: (Self.Iterator.Element) -> T) -> T {
		var result: T = 0
		for obj in self {
			result += numerator(obj)
		}
		return result
	}
	
	/// Sums up values of elements in self.
	public func sum<T: UnsignedInteger>(_ numerator: (Self.Iterator.Element) -> T) -> T {
		var result: T = 0
		for obj in self {
			result += numerator(obj)
		}
		return result
	}
	
	/// Sums up values of elements in self.
	public func sum(_ numerator: (Self.Iterator.Element) -> CGFloat) -> CGFloat {
		var result: CGFloat = 0.0
		for obj in self {
			result += numerator(obj)
		}
		return result
	}
	
	/// Sums up values of elements in self.
	public func sum(_ numerator: (Self.Iterator.Element) -> Double) -> Double {
		var result: Double = 0.0
		for obj in self {
			result += numerator(obj)
		}
		return result
	}
	
	/// Sums up values of elements in self.
	public func sum(_ numerator: (Self.Iterator.Element) -> NSDecimalNumber) -> NSDecimalNumber {
		var result: NSDecimalNumber = NSDecimalNumber.zero
		for obj in self {
			result = result.adding(numerator(obj))
		}
		return result
	}
	
	@available(*, deprecated, renamed: "Filter")
	public typealias XUFilter = Filter
	
	@available(*, deprecated, renamed: "all(matching:)")
	public func all(_ filter: XUFilter) -> Bool {
		return self.all(matching: filter)
	}
	
	@available(*, deprecated, renamed: "removing(matching:)")
	public func arrayByRemovingObjectsMatching(_ filter: XUFilter) -> [Self.Iterator.Element] {
		return self.removing(matching: filter)
	}
	
	@available(*, deprecated, renamed: "count(where:)")
	public func count( _ filter: XUFilter) -> Int {
		return self.count(where: filter)
	}
	
	@available(*, deprecated, renamed: "find(where:)")
	public func find( _ filter: XUFilter) -> Self.Iterator.Element? {
		return self.find(where: filter)
	}
	
}

public extension Sequence where Iterator.Element : Equatable {
	
	/// Returns true if the otherArray contains the same elements as self, but
	/// the order may differ.
	public func containsAll(from otherArray: [Self.Iterator.Element]) -> Bool {
		return self.all(matching: { otherArray.contains($0) })
	}
	
	/// Returns a distinct array. This means that it will toss away any duplicate
	/// items in self
	public func distinct() -> [Self.Iterator.Element] {
		var unique: [Self.Iterator.Element] = [ ]
		for item in self {
			if !unique.contains(item) {
				unique.append(item)
			}
		}
		return unique
	}
	
	@available(*, deprecated, renamed: "containsAll(from:)")
	public func containsAllObjectsFromArray(_ otherArray: [Self.Iterator.Element]) -> Bool {
		return containsAll(from: otherArray)
	}
	
}

public extension Array {
	
	/// Interlaces arrays. First, it takes the first elements of all arrays,
	/// then second, and so on. Doesn't take into account various array length
	/// in regards to element distribution.
	public init(interlacedArrays: [[Iterator.Element]]) {
		self.init()
		
		if interlacedArrays.count == 0 {
			return
		}
		
		if interlacedArrays.count == 1 {
			self.append(contentsOf: interlacedArrays[0])
			return
		}
		
		let maxIndex = interlacedArrays.findMax({ $0.count })!.count
		for i in 0..<maxIndex {
			for arr in interlacedArrays {
				if i < arr.count {
					self.append(arr[i])
				}
			}
		}
	}
	
	/// Similar to flatMap, but provides an index.
	public func flatMapIndexed<U>(_ mapper: (Int, Iterator.Element) -> U?) -> [U] {
		var result: [U] = [ ]
		for i in 0 ..< self.count {
			if let obj = mapper(i, self[i]) {
				result.append(obj)
			}
		}
		return result
	}
	
	/// Similar to map(), but provides the index of the element.
	public func mapIndexed<U>(_ mapper: (Iterator.Element, Int) -> U) -> [U] {
		var result: [U] = [ ]
		for i in 0..<Int(self.count) {
			result.append(mapper(self[i], i))
		}
		return result
	}
	
	/// Moves object from one index to another.
	public mutating func move(at fromIndex: Int, to toIndex: Int) {
		if toIndex == fromIndex {
			return
		}
		
		var targetIndex = toIndex
		if targetIndex >= fromIndex {
			targetIndex -= 1
		}
		
		let obj = self[fromIndex]
		self.remove(at: fromIndex)
		
		if targetIndex >= self.count {
			self.append(obj)
		} else {
			self.insert(obj, at: targetIndex)
		}
	}
	
	/// Returns a slice in range.
	public func slice(with range: Range<Int>) -> ArraySlice<Iterator.Element> {
		return self[range.lowerBound ..< range.upperBound]
	}
	
	@available(*, deprecated, renamed: "move(at:to:)")
	public mutating func moveObjectAtIndex(_ fromIndex: Int, toIndex: Int) {
		self.move(at: fromIndex, to: toIndex)
	}
	
	@available(*, deprecated, renamed: "slice(with:)")
	public func sliceWithRange(_ range: Range<Int>) -> ArraySlice<Iterator.Element> {
		return self.slice(with: range)
	}
}

public extension Collection where Self.IndexDistance : Comparable {
	
	/// This is the same as distinct(), but takes in a custom comparator for arrays
	/// that do not contain equatable elements.
	public func distinct(_ customComparator: (_ obj1: Self.Iterator.Element, _ obj2: Self.Iterator.Element) -> Bool) -> [Self.Iterator.Element] {
		var unique: [Self.Iterator.Element] = [ ]
		for val1 in self {
			var found = false
			for val2 in unique {
				if customComparator(val1, val2) {
					found = true
					break
				}
			}
			
			if !found {
				unique.append(val1)
			}
		}
		return unique
	}
	
}

public extension Array where Element : Equatable {

	/// Replaces all occurrences of `element` with `newElement`.
	public mutating func replaceAllOccurrences(of element: Iterator.Element, with newElement: Iterator.Element) {
		assert(element != newElement, "Trying to replace a value with the same value!")
		
		while let index = self.index(of: element) {
			self[index] = newElement
		}
	}
	
	@available(*, deprecated, renamed: "replaceAllOccurrences(of:with:)")
	public mutating func replaceAllOccurrences(_ element: Iterator.Element, withElement newElement: Iterator.Element) {
		self.replaceAllOccurrences(of: element, with: newElement)
	}
	
}

