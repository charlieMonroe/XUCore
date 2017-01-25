//
//  String+XURegexDeprecation.swift
//  XUCore
//
//  Created by Charlie Monroe on 1/25/17.
//  Copyright © 2017 Charlie Monroe Software. All rights reserved.
//

import Foundation

public extension String {
	
	@available(*, deprecated, renamed: "allOccurrences(ofRegex:)")
	public func allOccurrences(ofRegexString regexString: String) -> [String] {
		return self.allOccurrences(ofRegex: regexString)
	}
	
	@available(*, deprecated, renamed: "allValues(of:forRegex:)")
	public func allValues(ofVariableNamed varName: String, forRegex regex: XURegex) -> [String] {
		return self.allValues(of: varName, forRegex: regex)
	}
	
	@available(*, deprecated, renamed: "allValues(of:forRegex:)")
	public func allValues(ofVariableNamed varName: String, forRegexString regexString: String) -> [String] {
		return self.allValues(of: varName, forRegex: regexString)
	}
	
	@available(*, deprecated, renamed: "allVariablePairs(forRegex:)")
	public func allVariablePairs(forRegexString regexString: String) -> [String : String] {
		return self.allVariablePairs(forRegex: regexString)
	}
	
	@available(*, deprecated, renamed: "components(separatedByRegex:)")
	public func components(separatedByRegexString regexString: String) -> [String] {
		return self.components(separatedByRegex: regexString)
	}
	
	@available(*, deprecated, renamed: "firstOccurrence(ofRegex:)")
	public func firstOccurrence(ofRegexString regexString: String) -> String? {
		return self.firstOccurrence(ofRegex: regexString)
	}
	
	@available(*, deprecated, renamed: "firstOccurrence(ofAnyRegex:)")
	public func firstOccurrence(ofRegexStrings regexStrings: [String]) -> String? {
		return self.firstOccurrence(ofAnyRegex: regexStrings)
	}
	
	@available(*, deprecated, renamed: "firstOccurrence(ofAnyRegex:)")
	public func firstOccurrence(ofRegexStrings regexStrings: String...) -> String? {
		return self.firstOccurrence(ofAnyRegex: regexStrings)
	}
	
	@available(*, deprecated, renamed: "matches(anyOfRegexes:)")
	public func matches(anyOfRegexStrings regexStrings: [String]) -> Bool {
		return self.matches(anyOfRegexes: regexStrings)
	}
	
	@available(*, deprecated, renamed: "matches(regex:)")
	public func matches(regexString: String) -> Bool {
		return self.matches(regex: regexString)
	}
	
	@available(*, deprecated, renamed: "value(of:inRegex:)")
	public func value(ofVariableNamed name: String, inRegex regex: XURegex) -> String? {
		return value(of: name, inRegex: regex)
	}
	
	@available(*, deprecated, renamed: "value(of:inRegex:)")
	public func value(ofVariableNamed name: String, inRegexString regexString: String) -> String? {
		return value(of: name, inRegex: regexString)
	}
	
	@available(*, deprecated, renamed: "value(of:inRegexes:)")
	public func value(ofVariableNamed name: String, inRegexStrings regexStrings: String...) -> String? {
		return value(of: name, inRegexes: regexStrings)
	}
	
	@available(*, deprecated, renamed: "value(of:inRegexes:)")
	public func value(ofVariableNamed name: String, inRegexStrings regexStrings: [String]) -> String? {
		return value(of: name, inRegexes: regexStrings)
	}
}


public extension XURegex {
		
	@available(*, deprecated)
	convenience init(_ pattern: String) {
		self.init(pattern: pattern, andOptions: XURegexOptions())
	}
	
}

