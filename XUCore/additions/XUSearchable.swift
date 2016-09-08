//
//  XUSearchable.swift
//  XUCore
//
//  Created by Charlie Monroe on 12/20/15.
//  Copyright © 2015 Charlie Monroe Software. All rights reserved.
//

import Foundation


/// Implement this protocol on your classes to support the searchForString method.
public protocol XUSearchable {

	/// Returns a string in which the needle occurrs.
	func searchForString(_ needle: String) -> String?

}



extension Dictionary: XUSearchable {

	/// This method goes through all the values and tries to find an occurrence
	/// of the needle. It supports values of string, NSNumber, NSDate, arrays
	/// and recursively dictionaries. You can adopt the XUSearchable protocol
	/// on your classes to support this behavior.
	///
	/// If it finds something, it returns the entire value where the needle was
	/// found.
	public func searchForString(_ needle: String) -> String? {
		for (_, value) in self {
			if let searchable = value as? XUSearchable {
				if let result = searchable.searchForString(needle) {
					return result
				}
			}
		}
		
		return nil
	}

}

extension String: XUSearchable {
	
	/// Returns self, if the range of needle (case insensitive), is found.
	public func searchForString(_ needle: String) -> String? {
		if self.range(of: needle, options: .caseInsensitive) != nil {
			return self
		}
		return nil
	}
	
}

extension NSString: XUSearchable {
	
	/// Returns self, if the range of needle (case insensitive), is found.
	public func searchForString(_ needle: String) -> String? {
		if self.range(of: needle, options: .caseInsensitive).location != NSNotFound {
			return self as String
		}
		return nil
	}
	
}

extension NSNumber: XUSearchable {
	
	public func searchForString(_ needle: String) -> String? {
		if self.stringValue.range(of: needle, options: .caseInsensitive) != nil {
			return self.stringValue
		}
		return nil
	}
	
}

extension Date: XUSearchable {
	
	public func searchForString(_ needle: String) -> String? {
		if self.description.range(of: needle, options: .caseInsensitive) != nil {
			return self.description
		}
		return nil
	}
	
}

extension Array: XUSearchable {
	
	public func searchForString(_ needle: String) -> String? {
		for value in self {
			if let searchable = value as? XUSearchable {
				if let result = searchable.searchForString(needle) {
					return result
				}
			}
		}
		
		return nil
	}
	
}



