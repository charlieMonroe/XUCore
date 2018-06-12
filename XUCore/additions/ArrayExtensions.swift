//
//  ArrayExtensions.swift
//  DownieCore
//
//  Created by Charlie Monroe on 5/12/15.
//  Copyright (c) 2015 Charlie Monroe Software. All rights reserved.
//

import Foundation

public extension Sequence {
	
	public typealias Filter = (Self.Iterator.Element) throws -> Bool
	
	/// Returns true if all of the elements in self match the filter
	public func all(matching filter: Filter) rethrows -> Bool {
		return try self.first(where: { try !filter($0) }) == nil
	}
	
	/// Returns a compacted sequence - removing nil values.
	public func compacted<T>() -> [T] where Element == Optional<T> {
		return self.compactMap({ $0 })
	}
	
	/// Casts all elements in self to certain type - this is equivalent to
	/// array.compactMap({ $0 as? T }).
	public func compactCast<T>(to type: T.Type) -> [T] {
		return self.compactMap({ $0 as? T })
	}
	
	#if swift(>=4.1)
	#else
	/// This is a backward compatibility from Swift 4.1 which renames flatMap to
	/// compactMap.
	public func compactMap<U>(_ mapper: (Iterator.Element) throws -> U?) rethrows -> [U] {
		return try self.flatMap(mapper)
	}
	#endif
	
	/// Counts elements that match the filter
	public func count(where filter: Filter) rethrows -> Int {
		let count = try self.sum({ (obj) -> Int in
			return try filter(obj) ? 1 : 0
		})
		return count
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
	
	/// Randomizes the array (by shuffling it).
	public func randomized() -> [Self.Iterator.Element] {
		return self.sorted(by: { (_, _) -> Bool in
			return XURandomGenerator.shared.randomBoolean
		})
	}
	
	/// Returns a new array by removing objects that match the filter
	public func removing(matching filter: Filter) rethrows -> [Self.Iterator.Element] {
		var arr: [Self.Iterator.Element] = [ ]
		for obj in self {
			if try !filter(obj) {
				arr.append(obj)
			}
		}
		return arr
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
			self = interlacedArrays[0]
			return
		}
		
		let maxIndex = interlacedArrays.findMaxValue({ $0.count })!
		for i in 0 ..< maxIndex {
			for arr in interlacedArrays {
				if i < arr.count {
					self.append(arr[i])
				}
			}
		}
	}
	
	/// Similar to compactMap, but provides an index.
	public func compactMapIndexed<U>(_ mapper: (Int, Iterator.Element) -> U?) -> [U] {
		var result: [U] = []
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
		for i in 0 ..< self.count {
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
	
	/// Splits array into chunks of maximum size. The last chunk may be shorter.
	public func splitIntoChunks(ofSize chunkSize: Int) -> [[Iterator.Element]] {
		if self.isEmpty {
			return [[]]
		}
		
		let strideRun = stride(from: 0, to: self.count, by: chunkSize)
		return strideRun.map({
			let endIndex = Swift.min(self.count, $0.advanced(by: chunkSize))
			return Array(self[$0 ..< endIndex])
		})
	}
	
}

public extension Collection {
	
	/// This is the same as distinct(), but takes in a custom comparator for arrays
	/// that do not contain equatable elements.
	public func distinct(_ customComparator: (_ obj1: Self.Iterator.Element, _ obj2: Self.Iterator.Element) -> Bool) -> [Self.Iterator.Element] {
		var unique: [Self.Iterator.Element] = []
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
	
}

