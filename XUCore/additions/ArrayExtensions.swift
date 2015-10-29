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
	
	public func all(filter: (Self.Generator.Element) -> Bool) -> Bool {
		for obj in self {
			if !filter(obj) {
				return false
			}
		}
		
		return true
	}
	
	public func any(filter: (Self.Generator.Element) -> Bool) -> Bool {
		for obj in self {
			if filter(obj) {
				return true
			}
		}
		
		return false
	}
	
	public func arrayByRemovingObjectsMatching(filter: XUFilter) -> [Self.Generator.Element] {
		var arr: [Self.Generator.Element] = [ ]
		for obj in self {
			if !filter(obj) {
				arr.append(obj)
			}
		}
		return arr
	}
	
	public func count(filter: (Self.Generator.Element) -> Bool) -> UInt {
		let count =  self.sum({ (obj) -> Int in
			return filter(obj) ? 1 : 0
		})
		return UInt(count)
	}
	
	/** Unlike map, this allows you to return nil, in which case the value
	 * will be ommitted.
	 */
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
	
	public func find(filter: (Self.Generator.Element) -> Bool) -> Self.Generator.Element? {
		for obj in self {
			if filter(obj) {
				return obj
			}
		}
		return nil
	}
	
	public func findMapped<U>(filter: (Self.Generator.Element) -> U?) -> U? {
		for obj in self {
			let val = filter(obj)
			if val != nil {
				return val
			}
		}
		return nil
	}
	
	public func findMax(valuator: (Self.Generator.Element) -> UInt) -> Self.Generator.Element? {
		var maxElement: Self.Generator.Element? = nil
		var maxValue: UInt = 0
		
		for obj in self {
			let value = valuator(obj)
			if value > maxValue {
				maxValue = value
				maxElement = obj
			}
		}
		
		return maxElement
	}
	
	public func findMin(valuator: (Self.Generator.Element) -> Int) -> Self.Generator.Element? {
		var minElement: Self.Generator.Element? = nil
		var minValue: Int = Int.max
		
		for obj in self {
			let value = valuator(obj)
			if value > minValue {
				minValue = value
				minElement = obj
			}
		}
		
		return minElement
	}
	
	public func sum<T: SignedIntegerType>(numerator: (Self.Generator.Element) -> T) -> T {
		var result: T = 0
		for obj in self {
			result += numerator(obj)
		}
		return result
	}
	public func sum<T: UnsignedIntegerType>(numerator: (Self.Generator.Element) -> T) -> T {
		var result: T = 0
		for obj in self {
			result += numerator(obj)
		}
		return result
	}
	public func sum(numerator: (Self.Generator.Element) -> Double) -> Double {
		var result: Double = 0.0
		for obj in self {
			result += numerator(obj)
		}
		return result
	}
	
	
}

public extension SequenceType where Generator.Element : Equatable {
	
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
	
}

public extension CollectionType {
	
	public func distinct(customComparator: (obj1: Self.Generator.Element, obj2: Self.Generator.Element) -> Bool) -> [Self.Generator.Element] {
		var unique: [Self.Generator.Element] = [ ]
		for var i: Self.Index.Distance = 0; i < self.count; ++i {
			var found = false
			for var o: Self.Index.Distance = 0; o < self.count; ++o {
				if i == o {
					continue // Don't compare the same indexes!
				}
				
				if customComparator(obj1: self[self.startIndex.advancedBy(i)], obj2: self[self.startIndex.advancedBy(o)]) {
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

