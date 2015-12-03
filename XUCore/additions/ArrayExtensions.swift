//
//  ArrayExtensions.swift
//  DownieCore
//
//  Created by Charlie Monroe on 5/12/15.
//  Copyright (c) 2015 Charlie Monroe Software. All rights reserved.
//

import Foundation

public extension SequenceType {
	
	public typealias XUFilter = (Self.Generator.Element) -> Bool
	
	/// Returns true if all of the elements in self match the filter
	public func all(filter: XUFilter) -> Bool {
		return self.find({ !filter($0) }) == nil
	}
	
	/// Returns true if any of the elements in self matches the filter
	public func any(filter: XUFilter) -> Bool {
		return self.find(filter) != nil
	}
	
	/// Returns a new array by removing objects that match the filter
	public func arrayByRemovingObjectsMatching(filter: XUFilter) -> [Self.Generator.Element] {
		var arr: [Self.Generator.Element] = [ ]
		for obj in self {
			if !filter(obj) {
				arr.append(obj)
			}
		}
		return arr
	}
	
	/// Counts elements that match the filter
	public func count(filter: XUFilter) -> UInt {
		let count =  self.sum({ (obj) -> Int in
			return filter(obj) ? 1 : 0
		})
		return UInt(count)
	}
	
	/// Unlike map, this allows you to return nil, in which case the value
	/// will be ommitted.
	public func filterMap<U>(transform: (Self.Generator.Element) -> U?) -> [U] {
		var result: Array<U> = [ ]
		for obj in self {
			let transObj: U? = transform(obj)
			if let nonNilObj = transObj {
				result.append(nonNilObj)
			}
		}
		return result
	}
	
	/// Returns the first element in self that matches the filter
	public func find(filter: XUFilter) -> Self.Generator.Element? {
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
	public func findMapped<U>(filter: (Self.Generator.Element) -> U?) -> U? {
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
	public func findMax(valuator: (Self.Generator.Element) -> UInt) -> Self.Generator.Element? {
		var maxElement: Self.Generator.Element? = nil
		var maxValue: UInt = 0
		
		for obj in self {
			let value = valuator(obj)
			if value > maxValue || maxElement == nil {
				maxValue = value
				maxElement = obj
			}
		}
		
		return maxElement
	}
	
	/// Finds a minimum value within self. For non-empty arrays, always returns
	/// a non-nil value.
	public func findMin(valuator: (Self.Generator.Element) -> Int) -> Self.Generator.Element? {
		var minElement: Self.Generator.Element? = nil
		var minValue: Int = Int.max
		
		for obj in self {
			let value = valuator(obj)
			if value > minValue || minElement == nil {
				minValue = value
				minElement = obj
			}
		}
		
		return minElement
	}
	
	/// Sums up values of elements in self.
	public func sum<T: SignedIntegerType>(numerator: (Self.Generator.Element) -> T) -> T {
		var result: T = 0
		for obj in self {
			result += numerator(obj)
		}
		return result
	}
	
	/// Sums up values of elements in self.
	public func sum<T: UnsignedIntegerType>(numerator: (Self.Generator.Element) -> T) -> T {
		var result: T = 0
		for obj in self {
			result += numerator(obj)
		}
		return result
	}
	
	/// Sums up values of elements in self.
	public func sum(numerator: (Self.Generator.Element) -> Double) -> Double {
		var result: Double = 0.0
		for obj in self {
			result += numerator(obj)
		}
		return result
	}
	
	
}

public extension SequenceType where Generator.Element : Equatable {
	
	/// Returns a distinct array. This means that it will toss away any duplicate
	/// items in self
	public func distinct() -> [Self.Generator.Element] {
		var unique: [Self.Generator.Element] = [ ]
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
	public init(interlacedArrays: [[Generator.Element]]) {
		self.init()
		
		if interlacedArrays.count == 0 {
			return
		}
		
		if interlacedArrays.count == 1 {
			self.appendContentsOf(interlacedArrays[0])
			return
		}
		
		let maxIndex = interlacedArrays.findMax({ UInt($0.count) })!.count
		for var i = 0; i < maxIndex; ++i {
			for arr in interlacedArrays {
				if i < arr.count {
					self.append(arr[i])
				}
			}
		}
	}
	
	/// Similar to map(), but provides the index of the element.
	public func mapIndexed<U>(mapper: (Generator.Element, Int) -> U) -> [U] {
		var result: [U] = [ ]
		for i in 0..<Int(self.count) {
			result.append(mapper(self[i], i))
		}
		return result
	}
	
}

public extension CollectionType {
	
	/// This is the same as distinct(), but takes in a custom comparator for arrays
	/// that do not contain equatable elements.
	public func distinct(customComparator: (obj1: Self.Generator.Element, obj2: Self.Generator.Element) -> Bool) -> [Self.Generator.Element] {
		var unique: [Self.Generator.Element] = [ ]
		for var i: Self.Index.Distance = 0; i < self.count; ++i {
			var found = false
			for var o: Int = 0; o < unique.count; ++o {
				if customComparator(obj1: self[self.startIndex.advancedBy(i)], obj2: unique[unique.startIndex.advancedBy(o)]) {
					found = true
					break
				}
			}
			
			if !found {
				unique.append(self[self.startIndex.advancedBy(i)])
			}
		}
		return unique
	}

}

