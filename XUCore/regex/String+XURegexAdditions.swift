//
//  String+XURegexAdditions.swift
//  XUCore
//
//  Created by Charlie Monroe on 10/27/15.
//  Copyright © 2015 Charlie Monroe Software. All rights reserved.
//

import Foundation

public extension String {
	
	/// All Occurrences of regex in self.
	func allOccurrences(ofRegex regex: XURegex) -> [String] {
		return regex.allOccurrences(in: String(self))
	}
	
	/// All Occurrences of regex in self.
	///
	/// Convenience method that takes String as an argument rather than XURegex.
	/// Note that as the rest of these functions, all regex strings are compiled
	/// as caseless by default.
	func allOccurrences(ofRegex regexString: String, options: XURegexOptions = .caseless) -> [String] {
		return self.allOccurrences(ofRegex: XURegex(pattern: regexString, andOptions: options))
	}
	
	/// Returns all values of what getRegexVariableNamed would return in self.
	func allValues(of varName: String, forRegex regex: XURegex) -> [String] {
		return regex.allOccurrences(ofVariableNamed: varName, in: String(self))
	}
	
	/// Returns all values of what getRegexVariableNamed would return in self.
	///
	/// Convenience method that takes String as an argument rather than XURegex.
	/// Note that as the rest of these functions, all regex strings are compiled
	/// as caseless by default.
	func allValues(of varName: String, forRegex regexString: String, options: XURegexOptions = .caseless) -> [String] {
		return self.allValues(of: varName, forRegex: XURegex(pattern: regexString, andOptions: options))
	}
	
	/// Returns a dictionary of keys and values. This dictionary is created by
	/// mapping all occurrences of the regex in self into (key, value) pairs,
	/// where key is extracted by getting regex variable VARNAME in the match,
	/// value is extracted by getting regex variable VARVALUE in the match.
	///
	/// Example:
	///
	/// (?P<VARNAME>[^=]+)=(?P<VARVALUE>[^&]+)
	func allVariablePairs(forRegex regex: XURegex) -> [String : String] {
		return regex.allVariablePairs(in: String(self))
	}
	
	/// Returns a dictionary of keys and values. This dictionary is created by 
	/// mapping all occurrences of the regex in self into (key, value) pairs,
	/// where key is extracted by getting regex variable VARNAME in the match,
	/// value is extracted by getting regex variable VARVALUE in the match.
	///
	/// Example:
	///
	/// (?P<VARNAME>[^=]+)=(?P<VARVALUE>[^&]+)
	///
	/// Convenience method that takes String as an argument rather than XURegex.
	/// Note that as the rest of these functions, all regex strings are compiled
	/// as caseless by default.
	func allVariablePairs(forRegex regexString: String, options: XURegexOptions = .caseless) -> [String : String] {
		return self.allVariablePairs(forRegex: XURegex(pattern: regexString, andOptions: options))
	}
	
	/// Returns components separated by regex. Works pretty much like separating
	/// components by string or character set, but uses regex. Note that using an
	/// infinite regex will cause the method to call fatalError since it would
	/// lead to an infinite array.
	func components(separatedByRegex regex: XURegex) -> [String] {
		var result: [String] = []
		var searchString = self
		while let match = searchString.firstOccurrence(ofRegex: regex) {
			guard let range = searchString.range(of: match) , !range.isEmpty else {
				fatalError("The supplied regex \(regex) for components(separatedByRegex:) is infinite.")
			}
			
			result.append(String(searchString[searchString.startIndex ..< range.lowerBound]))
			searchString = String(searchString[range.upperBound...])
		}
		
		if result.isEmpty {
			return [String(self)]
		}
		
		return result
	}
	
	/// @see components(separatedByRegex:) - this is a convenience method that 
	/// takes in a regex string.
	func components(separatedByRegex regexString: String, options: XURegexOptions = .caseless) -> [String] {
		return self.components(separatedByRegex: XURegex(pattern: regexString, andOptions: options))
	}

	/// The most basic usage - first regex match.
	func firstOccurrence(ofRegex regex: XURegex) -> String? {
		return regex.firstMatch(in: String(self))
	}
	
	/// The most basic usage - first regex match.
	///
	/// Convenience method that takes String as an argument rather than XURegex.
	/// Note that as the rest of these functions, all regex strings are compiled
	/// as caseless by default.
	func firstOccurrence(ofRegex regexString: String, options: XURegexOptions = .caseless) -> String? {
		return self.firstOccurrence(ofRegex: XURegex(pattern: regexString, andOptions: options))
	}
	
	/// Iterates regex strings and returns the first one to return a nonnull match.
	///
	/// Convenience method that takes String as an argument rather than XURegex.
	/// Note that as the rest of these functions, all regex strings are compiled
	/// as caseless by default.
	func firstOccurrence(ofAnyRegex regexStrings: [String]) -> String? {
		for str in regexStrings {
			if let match = self.firstOccurrence(ofRegex: str) {
				return match
			}
		}
		return nil
	}
	
	/// Iterates regex strings and returns the first one to return a nonnull match.
	///
	/// Convenience method that takes String as an argument rather than XURegex.
	/// Note that as the rest of these functions, all regex strings are compiled
	/// as caseless by default.
	func firstOccurrence(ofAnyRegex regexStrings: String...) -> String? {
		return self.firstOccurrence(ofAnyRegex: regexStrings)
	}
	
	
	/// Returns true if any of the regex strings matches self.
	func matches(anyOfRegexes regexStrings: [String]) -> Bool {
		return regexStrings.contains(where: { self.matches(regex: $0) })
	}
	
	/// Returns true if the regex matches self.
	func matches(regex: XURegex) -> Bool {
		return self.firstOccurrence(ofRegex: regex) != nil
	}
	
	/// Returns true if the regex matches self.
	///
	/// Convenience method that takes String as an argument rather than XURegex.
	/// Note that as the rest of these functions, all regex strings are compiled
	/// as caseless by default.
	func matches(regex: String, options: XURegexOptions = .caseless) -> Bool {
		return self.matches(regex: XURegex(pattern: regex, andOptions: options))
	}
	
	/// Replaces occurrences of `regex` with `replacement`. Note that `replacement`
	/// currently needs to be a static string and can't refer to groups in `regex`.
	/// This method will call `fatalError` under 2 circumstances:
	///
	/// 1) When the replacement matches the regex. This would lead to infinite 
	///		loop and instead of looping, this is checked.
	/// 2) When the match is an empty string - again, this would lead to an 
	///		infinite loop and is caught.
	///
	/// While this is checked, there are still cases, where an infinite loop can
	/// be caused when the replacment will only partially match the regex.
	func replacingOccurrences(ofRegex regex: XURegex, with replacement: String) -> String {
		if replacement.matches(regex: regex) {
			fatalError("Replacement matches the regex. This would lead to infinite loop.")
		}
		
		var result = self
		while let match = result.firstOccurrence(ofRegex: regex) {
			if match.isEmpty {
				fatalError("Supplied regex is infinite - matches an empty string.")
			}
			
			result = result.replacingOccurrences(of: match, with: replacement)
		}
		
		return String(result)
	}
	
	/// Convenience method that takes a regex string instead. See the XURegex
	/// variant for more information.
	func replacingOccurrences(ofRegex regex: String, with replacement: String, options: XURegexOptions = .caseless) -> String {
		return self.replacingOccurrences(ofRegex: XURegex(pattern: regex, andOptions: options), with: replacement)
	}
	
	/// Returns the value of a variable with name in the regexes. For example:
	/// "data=(?P<DATA>.*)" has a named variable "DATA".
	func value(of name: String, inRegex regex: XURegex) -> String? {
		return regex.getVariableNamed(name, in: String(self))
	}
	
	/// Returns the value of a variable with name in the regex. For example:
	/// "data=(?P<DATA>.*)" has a named variable "DATA".
	///
	/// Convenience method that takes String as an argument rather than XURegex.
	/// Note that as the rest of these functions, all regex strings are compiled
	/// as caseless by default.
	func value(of name: String, inRegex regexString: String, options: XURegexOptions = .caseless) -> String? {
		return self.value(of: name, inRegex: XURegex(pattern: regexString, andOptions: options))
	}
	
	/// Returns the value of a variable with name in the regexes. For example:
	/// "data=(?P<DATA>.*)" has a named variable "DATA".
	func value(of name: String, inRegexes regexStrings: String...) -> String? {
		return self.value(of: name, inRegexes: regexStrings)
	}
	
	/// Returns the value of a variable with name in the regexes. For example:
	/// "data=(?P<DATA>.*)" has a named variable "DATA".
	func value(of name: String, inRegexes regexStrings: [String]) -> String? {
		for regexString in regexStrings {
			if let match = self.value(of: name, inRegex: regexString) {
				return match
			}
		}
		return nil
	}
	
}

