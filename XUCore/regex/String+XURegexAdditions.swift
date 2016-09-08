//
//  NSString+XURegexAdditions.swift
//  DownieCore
//
//  Created by Charlie Monroe on 10/27/15.
//  Copyright © 2015 Charlie Monroe Software. All rights reserved.
//

import Foundation

public extension String {
	
	fileprivate func _standardizedURLFromURLString(_ originalURLString: String) -> [URL]? {
		var URLString = originalURLString
		if URLString.hasPrefix("//") {
			URLString = "http:" + URLString
		}else if !URLString.hasPrefix("http") && !URLString.hasPrefix("rtmp") && !URLString.hasPrefix("rtme") {
			URLString = "http://" + URLString
		}
		
		if URLString.range(of: "&amp;") != nil {
			URLString = URLString.HTMLUnescapedString
		}
		
		if let decoded = URLString.removingPercentEncoding {
			if URLString.range(of: "%3D") != nil && Foundation.URL(string: decoded) != nil {
				URLString = decoded
			}
		}
		
		if URLString.range(of: " ") != nil {
			URLString = URLString.replacingOccurrences(of: " ", with: "%20")
		}
		
		if URLString.components(separatedBy: "#").count > 2 {
			URLString = URLString.replacingOccurrences(of: "#", with: "%23")
		}
		
		var URL = Foundation.URL(string: URLString)
		if URL == nil {
			if let decoded = URLString.removingPercentEncoding {
				URL = Foundation.URL(string: decoded)
			}
		}
		
		if URL == nil {
			URL = Foundation.URL(string: URLString.HTMLUnescapedString)
		}
		
		if URL == nil {
			return nil
		}
		
		if URL!.path.range(of: "//") != nil {
			var path = URL!.path.replacingOccurrences(of: "//", with: "/") 
			if path.characters.count == 0 {
				path = "/"
			}
			
			if (URL!.scheme?.characters.count)! > 0 {
				URL = NSURL(scheme: URL!.scheme!, host: URL!.host, path: path) as? URL
			}
		}
		
		URLString = URL!.absoluteString
		if URLString.range(of: "&") != nil && URLString.range(of: "?") == nil {
			if let firstURL = Foundation.URL(string: URLString.components(separatedBy: "&").first!) {
				return [URL, firstURL].flatMap({ $0 })
			}
		}
		
		return [URL!]
	}
	
	fileprivate func _URLStringOccurrencesToNSURLs(_ occurrences: [String]) -> [URL] {
		var URLs: [URL] = [ ]
		
		URLs += occurrences.flatMap({ (originalURLString) -> [URL]? in
			return self._standardizedURLFromURLString(originalURLString)
		}).joined()
		
		URLs = URLs.distinct({ ($0 == $1) })
		URLs = URLs.flatMap({ (URL) -> Foundation.URL? in
			if URL.host == nil {
				return nil
			}
			
			if URL.scheme?.characters.count == 0 {
				return (NSURL(scheme: "http", host: URL.host, path: URL.path.characters.count == 0 ? "/" : URL.path) as? URL)
			}
			
			return URL
		})
		
		return URLs
	}
	
	/// All Occurrences of regex in self.
	public func allOccurrencesOfRegex(_ regex: XURegex) -> [String] {
		return regex.allOccurrences(in: self)
	}
	
	/// All Occurrences of regex in self.
	///
	/// Convenience method that takes String as an argument rather than XURegex.
	/// Note that as the rest of these functions, all regex strings are compiled
	/// as caseless by default.
	public func allOccurrencesOfRegexString(_ regexString: String) -> [String] {
		return self.allOccurrencesOfRegex(XURegex(pattern: regexString, andOptions: .caseless))
	}
	
	/// Attempts to find all relative URLs in the self.
	public func allRelativeURLsToURL(_ baseURL: URL) -> [URL] {
		let regex = XURegex(pattern: "(?i)/[^\\s'\"<>]+", andOptions: XURegexOptions())
		
		var occurrences = regex.allOccurrences(in: self)
		occurrences += self.allValuesOfVariableNamed("URL", forRegexString: XURegex.URL.sourceSource.regexString)
		occurrences += self.allValuesOfVariableNamed("URL", forRegexString: XURegex.URL.videoSource.regexString)
		occurrences += self.allValuesOfVariableNamed("URL", forRegexString: XURegex.URL.iframeSource.regexString)
		occurrences += self.allValuesOfVariableNamed("URL", forRegexString: "<a[^>]+href=\"(?P<URL>[^\"]+)\"")
		
		occurrences = occurrences.flatMap({ (URLString) -> String? in
			if URLString.hasPrefix("http") || URLString.hasPrefix("//") {
				return nil /* We want just relative URLs. */
			}
			
			return URL(string: URLString, relativeTo: baseURL)?.absoluteString
		})
		
		return self._URLStringOccurrencesToNSURLs(occurrences)
	}
	
	/// Returns all relative URLs to URL created by "/" path and http scheme.
	public func allRelativeURLsWithHost(_ host: String) -> [URL] {
		guard let baseURL = NSURL(scheme: "http", host: host, path: "/") as? URL else {
			return [ ]
		}
		return self.allRelativeURLsToURL(baseURL)
	}
	
	/// Attempts to find all absolute URLs in self. Uses various heuristics to
	/// do so.
	public var allURLs: [URL] {
		let regex = XURegex(pattern: "(?i)(?:(?:[a-z]{2,8}:)?//)?([a-z0-9\\-_]\\.?)*[a-z0-9\\-_]+\\.[a-z0-9\\-_]+(?::\\d+)?(/[^\\(\\)<>\"'\\$\\\\\n\r]*)", andOptions: .caseless)
		var occurrences = regex.allOccurrences(in: self.replacingOccurrences(of: "\r", with: "\n"))
		
		/** Unfortunely some sites idiotically include spaces in the URLs. This is an easy workaround... */
		occurrences += self.allValuesOfVariableNamed("URL", forRegexString: "<a[^>]+href=\"(?P<URL>[^\"]+)\"")
		occurrences += self.allValuesOfVariableNamed("URL", forRegexString: XURegex.URL.iframeSource.regexString)
		if let ogVideo = self.getRegexVariableNamed("URL", forRegex: XURegex.URL.metaOGVideo.regex) {
			occurrences.append(ogVideo)
		}
		
		return self._URLStringOccurrencesToNSURLs(occurrences)
	}
	
	/// Returns all values of what getRegexVariableNamed would return in self.
	public func allValuesOfVariableNamed(_ varName: String, forRegex regex: XURegex) -> [String] {
		return regex.allOccurrences(ofVariableNamed: varName, in: self)
	}
	
	/// Returns all values of what getRegexVariableNamed would return in self.
	///
	/// Convenience method that takes String as an argument rather than XURegex.
	/// Note that as the rest of these functions, all regex strings are compiled
	/// as caseless by default.
	public func allValuesOfVariableNamed(_ varName: String, forRegexString regexString: String) -> [String] {
		return self.allValuesOfVariableNamed(varName, forRegex: XURegex(pattern: regexString, andOptions: .caseless))
	}
	
	/// Returns a dictionary of keys and values. This dictionary is created by
	/// mapping all occurrences of the regex in self into (key, value) pairs,
	/// where key is extracted by getting regex variable VARNAME in the match,
	/// value is extracted by getting regex variable VARVALUE in the match.
	///
	/// Example:
	///
	/// (?P<VARNAME>[^=]+)=(?P<VARVALUE>[^&]+)
	public func allVariablePairsForRegex(_ regex: XURegex) -> [String : String] {
		return regex.allVariablePairs(in: self)
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
	public func allVariablePairsForRegexString(_ regexString: String) -> [String : String] {
		return self.allVariablePairsForRegex(XURegex(pattern: regexString, andOptions: .caseless))
	}
	
	/// Returns components separated by regex. Works pretty much like separating
	/// components by string or character set, but uses regex. Note that using an
	/// infinite regex will cause the method to call fatalError since it would
	/// lead to an infinite array.
	public func components(separatedByRegex regex: XURegex) -> [String] {
		var result: [String] = []
		var searchString = self
		while let match = searchString.firstOccurrenceOfRegex(regex) {
			guard let range = searchString.range(of: match) , !range.isEmpty else {
				fatalError("The supplied regex \(regex) for components(separatedByRegex:) is infinite.")
			}
			
			result.append(searchString.substring(with: searchString.startIndex ..< range.lowerBound))
			searchString = searchString.substring(from: range.upperBound)
		}
		
		if result.isEmpty {
			return [self]
		}
		
		return result
	}
	
	/// @see components(separatedByRegex:) - this is a convenience method that 
	/// takes in a regex string.
	public func components(separatedByRegexString regexString: String) -> [String] {
		return self.components(separatedByRegex: XURegex(pattern: regexString, andOptions: .caseless))
	}

	/// The most basic usage - first regex match.
	public func firstOccurrenceOfRegex(_ regex: XURegex) -> String? {
		return regex.firstMatch(in: self)
	}
	
	/// The most basic usage - first regex match.
	///
	/// Convenience method that takes String as an argument rather than XURegex.
	/// Note that as the rest of these functions, all regex strings are compiled
	/// as caseless by default.
	public func firstOccurrenceOfRegexString(_ regexString: String) -> String? {
		return self.firstOccurrenceOfRegex(XURegex(pattern: regexString, andOptions: .caseless))
	}
	
	/// Iterates regex strings and returns the first one to return a nonnull match.
	///
	/// Convenience method that takes String as an argument rather than XURegex.
	/// Note that as the rest of these functions, all regex strings are compiled
	/// as caseless by default.
	public func firstOccurrenceOfRegexStrings(_ regexStrings: [String]) -> String? {
		for str in regexStrings {
			if let match = self.firstOccurrenceOfRegexString(str) {
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
	public func firstOccurrenceOfRegexStrings(_ regexStrings: String...) -> String? {
		return self.firstOccurrenceOfRegexStrings(regexStrings)
	}
	
	
	/// Returns the value of a variable with name in the regexes. For example:
	/// "data=(?P<DATA>.*)" has a named variable "DATA".
	public func getRegexVariableNamed(_ name: String, forRegex regex: XURegex) -> String? {
		return regex.getVariableNamed(name, in: self)
	}
	
	/// Returns the value of a variable with name in the regex. For example:
	/// "data=(?P<DATA>.*)" has a named variable "DATA".
	///
	/// Convenience method that takes String as an argument rather than XURegex.
	/// Note that as the rest of these functions, all regex strings are compiled
	/// as caseless by default.
	public func getRegexVariableNamed(_ name: String, forRegexString regexString: String) -> String? {
		return self.getRegexVariableNamed(name, forRegex: XURegex(pattern: regexString, andOptions: .caseless))
	}
	
	/// Returns the value of a variable with name in the regexes. For example:
	/// "data=(?P<DATA>.*)" has a named variable "DATA".
	public func getRegexVariableNamed(_ name: String, forRegexStrings regexStrings: String...) -> String? {
		return self.getRegexVariableNamed(name, forRegexStrings: regexStrings)
	}
	
	/// Returns the value of a variable with name in the regexes. For example:
	/// "data=(?P<DATA>.*)" has a named variable "DATA".
	public func getRegexVariableNamed(_ name: String, forRegexStrings regexStrings: [String]) -> String? {
		for regexString in regexStrings {
			if let match = self.getRegexVariableNamed(name, forRegexString: regexString) {
				return match
			}
		}
		return nil
	}
	
	/// Returns true if any of the regex strings matches self.
	public func matchesAnyOfRegexStrings(_ regexStrings: [String]) -> Bool {
		return regexStrings.contains(where: { self.matchesRegexString($0) })
	}
	
	/// Returns true if the regex matches self.
	public func matchesRegex(_ regex: XURegex) -> Bool {
		return self.firstOccurrenceOfRegex(regex) != nil
	}
	
	/// Returns true if the regex matches self.
	///
	/// Convenience method that takes String as an argument rather than XURegex.
	/// Note that as the rest of these functions, all regex strings are compiled
	/// as caseless by default.
	public func matchesRegexString(_ regexString: String) -> Bool {
		return self.matchesRegex(XURegex(pattern: regexString, andOptions: .caseless))
	}
	
}

