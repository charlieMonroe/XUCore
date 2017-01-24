//
//  XUSearchable.swift
//  XUCore
//
//  Created by Charlie Monroe on 12/20/15.
//  Copyright © 2015 Charlie Monroe Software. All rights reserved.
//

import Foundation


/// Implement this protocol on your classes to support the searchForString method.
@available(*, deprecated)
public protocol XUSearchable {

	/// Returns a string in which the needle occurrs.
	func search(for needle: String) -> String?

}


@available(*, deprecated)
extension Dictionary: XUSearchable {

	/// This method goes through all the values and tries to find an occurrence
	/// of the needle. It supports values of string, NSNumber, NSDate, arrays
	/// and recursively dictionaries. You can adopt the XUSearchable protocol
	/// on your classes to support this behavior.
	///
	/// If it finds something, it returns the entire value where the needle was
	/// found.
	public func search(for needle: String) -> String? {
		for (_, value) in self {
			if let searchable = value as? XUSearchable {
				if let result = searchable.search(for: needle) {
					return result
				}
			}
		}
		
		return nil
	}

}

@available(*, deprecated)
extension String: XUSearchable {
	
	/// Returns self, if the range of needle (case insensitive), is found.
	@available(*, deprecated)
	public func search(for needle: String) -> String? {
		if self.range(of: needle, options: .caseInsensitive) != nil {
			return self
		}
		return nil
	}
	
}

@available(*, deprecated)
extension NSString: XUSearchable {
	
	/// Returns self, if the range of needle (case insensitive), is found.
	public func search(for needle: String) -> String? {
		if self.range(of: needle, options: .caseInsensitive).location != NSNotFound {
			return self as String
		}
		return nil
	}
	
}

@available(*, deprecated)
extension NSNumber: XUSearchable {
	
	public func search(for needle: String) -> String? {
		if self.stringValue.range(of: needle, options: .caseInsensitive) != nil {
			return self.stringValue
		}
		return nil
	}
	
}

@available(*, deprecated)
extension Date: XUSearchable {
	
	public func search(for needle: String) -> String? {
		if self.description.range(of: needle, options: .caseInsensitive) != nil {
			return self.description
		}
		return nil
	}
	
}

@available(*, deprecated)
extension Array: XUSearchable {
	
	public func search(for needle: String) -> String? {
		for value in self {
			if let searchable = value as? XUSearchable {
				if let result = searchable.search(for: needle) {
					return result
				}
			}
		}
		
		return nil
	}
	
}



