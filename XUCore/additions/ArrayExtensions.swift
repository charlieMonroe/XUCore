//
//  ArrayExtensions.swift
//  DownieCore
//
//  Created by Charlie Monroe on 5/12/15.
//  Copyright (c) 2015 Charlie Monroe Software. All rights reserved.
//

import Foundation

extension Sequence {
	
	public typealias Filter = (Self.Element) throws -> Bool
		
	/// Returns a compacted sequence - removing nil values.
	public func compacted<T>() -> [T] where Element == Optional<T> {
		return self.compactMap({ $0 })
	}
	
	/// Casts all elements in self to certain type - this is equivalent to
	/// array.compactMap({ $0 as? T }).
	public func compactCast<T>(to type: T.Type) -> [T] {
		return self.compactMap({ $0 as? T })
	}
	
	/// Returns if there is an element that has a value under keyPath equal to value. The following statements are equivalent:
	///
	/// - contains(where: { $0.uuid == someUUID })
	/// - containsElement(with: \.uuid, equalTo: someUUID)
	public func containsElement<T: Equatable>(with keyPath: KeyPath<Element, T>, equalTo value: T?) -> Bool {
		return self.first(with: keyPath, equalTo: value) != nil
	}
	
	/// Counts elements that match the filter
	public func count(where filter: Filter) rethrows -> Int {
		let count = try self.sum({ (obj) -> Int in
			return try filter(obj) ? 1 : 0
		})
		return count
	}
		
	/// Finds a mapped value. When `transformation` returns a non-nil value, that value
	/// is returned. This way you can do some computation in the block and return
	/// the value without the need of doing the computation again
	public func firstNonNilValue<U>(using transformation: (Self.Element) -> U?) -> U? {
		for obj in self {
			if let val = transformation(obj) {
				return val
			}
		}
		return nil
	}
	
	/// Returns first element that has a value under keyPath equal to value. The following statements are equivalent:
	///
	/// - first(where: { $0.uuid == someUUID })
	/// - first(with: \.uuid, equalTo: someUUID)
	public func first<T: Equatable>(with keyPath: KeyPath<Element, T>, equalTo value: T?) -> Element? {
		return self.first(where: { $0[keyPath: keyPath] == value })
	}
	
	/// Returns first element of type T.
	///
	/// Note: equivalent to self.firstNonNilValue(using: { $0 as? T })
	public func first<T>(ofType type: T.Type) -> T? {
		return self.firstNonNilValue(using: { $0 as? T })
	}
	
	/// Finds a maximum value within self. For non-empty arrays, always returns
	/// a non-nil value.
	public func findMax<T: Comparable>(_ valuator: (Self.Element) -> T) -> Self.Element? {
		var maxElement: Self.Element? = nil
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
	public func findMaxValue<T: Comparable>(_ valuator: (Self.Element) -> T) -> T? {
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
	public func findMin<T: Comparable>(_ valuator: (Self.Element) -> T) -> Self.Element? {
		var minElement: Self.Element? = nil
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
	public func findMinValue<T: Comparable>(_ valuator: (Self.Element) -> T) -> T? {
		var minValue: T? = nil
		
		for obj in self {
			let value = valuator(obj)
			if minValue == nil || value < minValue! {
				minValue = value
			}
		}
		
		return minValue
	}
	
	/// Maps a sequence to a result of a keyPath.
	public func map<T>(_ keyPath: KeyPath<Self.Element, T>) -> [T] {
		return self.map({ $0[keyPath: keyPath] })
	}
	
	/// Randomizes the array (by shuffling it).
	public func randomized() -> [Self.Element] {
		return self.sorted(by: { (_, _) -> Bool in
			return XURandomGenerator.shared.randomBoolean
		})
	}
	
	/// Returns a new array by removing objects that match the filter
	public func removing(matching filter: Filter) rethrows -> [Self.Element] {
		var arr: [Self.Element] = [ ]
		for obj in self {
			if try !filter(obj) {
				arr.append(obj)
			}
		}
		return arr
	}
	
}

extension Sequence where Iterator.Element : Equatable {
	
	/// Returns common elements that this sequence shares with `otherSequence`.
	public func commonElements<T: Sequence>(with otherSequence: T) -> [Iterator.Element] where T.Element == Iterator.Element {
		var arr: [Iterator.Element] = []
		for x in self {
			for y in otherSequence {
				if x == y {
					arr.append(x)
				}
			}
		}
		return arr
	}
	
	/// Returns true if the otherArray contains the same elements as self, but
	/// the order may differ.
	public func containsAll(from otherArray: [Self.Element]) -> Bool {
		return self.allSatisfy({ otherArray.contains($0) })
	}
	
	/// Returns a distinct array. This means that it will toss away any duplicate
	/// items in self
	public func distinct() -> [Self.Element] {
		var unique: [Self.Element] = []
		for item in self {
			if !unique.contains(item) {
				unique.append(item)
			}
		}
		return unique
	}
	
}

extension Array {
	
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
		
	/// Moves object from one index to another.
	public mutating func move(at fromIndex: Int, to toIndex: Int) {
		if toIndex == fromIndex {
			return
		}
		
		let obj = self[fromIndex]
		self.remove(at: fromIndex)
		
		if toIndex >= self.count {
			self.append(obj)
		} else {
			self.insert(obj, at: toIndex)
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

extension Array where Element: Hashable {
	
	/// An optimized version of the distinct function for hashable elements that uses Set for ensuring the
	/// uniqueness.
	public func distinct() -> [Self.Element] {
		var result: [Self.Element] = []
		result.reserveCapacity(self.count)
		
		var set: Set<Self.Element> = Set()
		
		for value in self {
			if set.insert(value).inserted {
				result.append(value)
			}
		}
				
		return result
	}
	
}

extension Collection where Element: Hashable {
	
	/// An optimized version of the distinct function for hashable elements that uses Set for ensuring the
	/// uniqueness.
	public func distinct() -> [Self.Element] {
		var result: [Self.Element] = []
		result.reserveCapacity(self.count)
		
		var set: Set<Self.Element> = Set()
		
		for value in self {
			if set.insert(value).inserted {
				result.append(value)
			}
		}
				
		return result
	}
	
}

extension Sequence where Element: Hashable {
	
	/// An optimized version of the distinct function for hashable elements that uses Set for ensuring the
	/// uniqueness.
	public func distinct() -> [Self.Element] {
		var result: [Self.Element] = []
		result.reserveCapacity(self.underestimatedCount)
		
		var set: Set<Self.Element> = Set()
		
		for value in self {
			if set.insert(value).inserted {
				result.append(value)
			}
		}
				
		return result
	}
	
}

extension Collection {
	
	/// This is the same as distinct(), but takes in a custom comparator for arrays
	/// that do not contain equatable elements.
	public func distinct(_ customComparator: (_ obj1: Self.Element, _ obj2: Self.Element) -> Bool) -> [Self.Element] {
		var unique: [Self.Element] = []
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
	
	/// Sorts the collection using a keyPath.
	public func sorted<T: Comparable>(using keyPath: KeyPath<Self.Element, T>) -> [Self.Element] {
		return self.sorted {
			$0[keyPath: keyPath] < $1[keyPath: keyPath]
		}
	}
	
	/// Sorts the collection using a keyPath.
	public func sorted(using keyPath: KeyPath<Self.Element, String>, options: String.CompareOptions) -> [Self.Element] {
		return self.sorted {
			$0[keyPath: keyPath].compare($1[keyPath: keyPath], options: options) == .orderedAscending
		}
	}
	
}

extension Array where Element : Equatable {

	/// Replaces all occurrences of `element` with `newElement`.
	public mutating func replaceAllOccurrences(of element: Iterator.Element, with newElement: Iterator.Element) {
		XUAssert(element != newElement, "Trying to replace a value with the same value!")
		
		while let index = self.firstIndex(of: element) {
			self[index] = newElement
		}
	}
	
}

extension BidirectionalCollection {
	
	/// Extended enumerator. It includes previous, current and next values. This
	/// way you can more easily look forward and backward without tracking previous
	/// values.
	///
	/// You can use it e.g. like this:
	///
	/// for (previous, current, next) in collection.extendedEnumerator() {
	///     // ...
	/// }
	///
	public func extendedEnumerator() -> XUExtendedEnumerator<Element> {
		return XUExtendedEnumerator(collection: AnyBidirectionalCollection<Element>(self))
	}
	
}

public struct XUExtendedIterator<T>: IteratorProtocol {
	
	public typealias Element = (previous: T?, current: T, next: T?)
	
	
	/// Current index.
	public private(set) var currentIndex: AnyBidirectionalCollection<T>.Index
	
	/// Collection we're iterating.
	public let collection: AnyBidirectionalCollection<T>

	
	private mutating func _increaseIndex() {
		self.currentIndex = self.collection.index(after: self.currentIndex)
	}
	
	public mutating func next() -> Element? {
		defer {
			self._increaseIndex()
		}
		
		if self.collection.isEmpty {
			return nil
		}
		
		let previousIndex = self.collection.index(before: self.currentIndex)
		let nextIndex = self.collection.index(after: self.currentIndex)
		if nextIndex < self.collection.endIndex {
			if previousIndex < self.collection.startIndex {
				return (nil, self.collection[self.currentIndex], self.collection[nextIndex])
			} else {
				return (self.collection[previousIndex], self.collection[self.currentIndex], self.collection[nextIndex])
			}
		} else {
			if previousIndex < self.collection.startIndex {
				return (nil, self.collection[self.currentIndex], nil)
			} else {
				return (self.collection[previousIndex], self.collection[self.currentIndex], nil)
			}
		}
	}
	
	public init(collection: AnyBidirectionalCollection<T>) {
		self.collection = collection
		self.currentIndex = collection.startIndex
	}
	
}

public struct XUExtendedEnumerator<T>: BidirectionalCollection {
	
	public typealias Element = XUExtendedIterator<T>.Element
	public typealias Index = AnyBidirectionalCollection<T>.Index
	
	/// Collection.
	public let collection: AnyBidirectionalCollection<T>
	
	public var endIndex: AnyBidirectionalCollection<T>.Index {
		return self.collection.endIndex
	}
	
	public func index(after i: AnyBidirectionalCollection<T>.Index) -> AnyBidirectionalCollection<T>.Index {
		return self.collection.index(after: i)
	}
	
	public func index(before i: AnyBidirectionalCollection<T>.Index) -> AnyBidirectionalCollection<T>.Index {
		return self.collection.index(before: i)
	}
	
	public var startIndex: AnyBidirectionalCollection<T>.Index {
		return self.collection.startIndex
	}
	
	public subscript(index: Index) -> Element {
		let previousIndex = self.collection.index(before: index)
		let previous = previousIndex < self.collection.startIndex ? nil : self.collection[previousIndex]
		
		let nextIndex = self.collection.index(after: index)
		let next = nextIndex < self.collection.endIndex ? self.collection[nextIndex] : nil
		
		return (previous, self.collection[index], next)
	}
	
	public init(collection: AnyBidirectionalCollection<T>) {
		self.collection = collection
	}
	
}

