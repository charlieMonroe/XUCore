//
//  XUSearchable.swift
//  XUCore
//
//  Created by Charlie Monroe on 12/20/15.
//  Copyright © 2015 Charlie Monroe Software. All rights reserved.
//

import Foundation


/// Implement this protocol on your classes to support the search(for:) method.
/// This allows searching within dictionaries and arrays of objects for a fulltext
/// result.
public protocol XUSearchable {

	/// Returns a string in which the needle occurrs.
	func search(for needle: String) -> XUSearchResult?

}

/// Search result returned by the XUSearchable.
public struct XUSearchResult {
	
	/// The keypath under which the result was found.
	public var keyPath: [String]
	
	/// The value in which the needle was found.
	public let resultValue: Any
	
	/// Description of the result value.
	public let resultValueDescription: String
	
	/// Initializes with resultValue that is a string. The resultValueDescription
	/// is automatically this string. Keypath is initialized to an empty array.
	public init(resultValue: String) {
		self.keyPath = []
		self.resultValue = resultValue
		self.resultValueDescription = resultValue
	}
	
	/// Initializes with resultValue. Keypath is initialized to an empty array.
	public init(resultValue: Any, resultValueDescription: String) {
		self.keyPath = []
		self.resultValue = resultValue
		self.resultValueDescription = resultValueDescription
	}
	
}


extension Dictionary: XUSearchable {

	/// This method goes through all the values and tries to find an occurrence
	/// of the needle. It supports values of string, NSNumber, NSDate, arrays
	/// and recursively dictionaries. You can adopt the XUSearchable protocol
	/// on your classes to support this behavior.
	///
	/// If it finds something, it returns the entire value where the needle was
	/// found.
	public func search(for needle: String) -> XUSearchResult? {
		for (key, value) in self {
			if let searchable = value as? XUSearchable {
				if var result = searchable.search(for: needle) {
					result.keyPath.insert("\(key)", at: 0)
					return result
				}
			}
		}
		
		return nil
	}

}

extension String: XUSearchable {
	
	/// Returns self, if the range of needle (case insensitive), is found.
	public func search(for needle: String) -> XUSearchResult? {
		if self.range(of: needle, options: .caseInsensitive) != nil {
			return XUSearchResult(resultValue: self)
		}
		return nil
	}
	
}

extension NSString: XUSearchable {
	
	/// Returns self, if the range of needle (case insensitive), is found.
	public func search(for needle: String) -> XUSearchResult? {
		return (self as String).search(for: needle)
	}
	
}

extension NSNumber: XUSearchable {
	
	public func search(for needle: String) -> XUSearchResult? {
		if self.stringValue.range(of: needle, options: .caseInsensitive) != nil {
			return XUSearchResult(resultValue: self, resultValueDescription: self.stringValue)
		}
		return nil
	}
	
}

extension Int: XUSearchable {
	
	public func search(for needle: String) -> XUSearchResult? {
		return (self as NSNumber).search(for: needle)
	}
	
}

extension Double: XUSearchable {
	
	public func search(for needle: String) -> XUSearchResult? {
		return (self as NSNumber).search(for: needle)
	}
	
}

extension Date: XUSearchable {
	
	public func search(for needle: String) -> XUSearchResult? {
		if self.description.range(of: needle, options: .caseInsensitive) != nil {
			return XUSearchResult(resultValue: self, resultValueDescription: self.description)
		}
		return nil
	}
	
}

extension NSDate: XUSearchable {
	
	public func search(for needle: String) -> XUSearchResult? {
		return (self as Date).search(for: needle)
	}
	
}

extension Array: XUSearchable {
	
	public func search(for needle: String) -> XUSearchResult? {
		for (index, value) in self.enumerated() {
			if let searchable = value as? XUSearchable {
				if var result = searchable.search(for: needle) {
					result.keyPath.insert("\(index)", at: 0)
					return result
				}
			}
		}
		
		return nil
	}
	
}
