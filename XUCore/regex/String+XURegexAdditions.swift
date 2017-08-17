//
//  String+XURegexAdditions.swift
//  XUCore
//
//  Created by Charlie Monroe on 10/27/15.
//  Copyright © 2015 Charlie Monroe Software. All rights reserved.
//

import Foundation

public extension String {
	
	private func _standardizedURL(from originalURLString: String) -> [URL]? {
		var urlString = originalURLString
		if urlString.hasPrefix("//") {
			urlString = "http:" + urlString
		}else if !urlString.hasPrefix("http") && !urlString.hasPrefix("rtmp") && !urlString.hasPrefix("rtme") {
			urlString = "http://" + urlString
		}
		
		if urlString.range(of: "&amp;") != nil {
			urlString = urlString.htmlUnescapedString
		}
		
		if let decoded = urlString.removingPercentEncoding {
			if urlString.range(of: "%3D") != nil && URL(string: decoded) != nil {
				urlString = decoded
			}
		}
		
		if urlString.range(of: " ") != nil {
			urlString = urlString.replacingOccurrences(of: " ", with: "%20")
		}
		
		if urlString.components(separatedBy: "#").count > 2 {
			urlString = urlString.replacingOccurrences(of: "#", with: "%23")
		}
		
		var url = URL(string: urlString)
		if url == nil {
			if let decoded = urlString.removingPercentEncoding {
				url = URL(string: decoded)
			}
		}
		
		if url == nil {
			url = URL(string: urlString.htmlUnescapedString)
		}
		
		if url == nil {
			return nil
		}
		
		if url!.path.range(of: "//") != nil {
			var path = url!.path.replacingOccurrences(of: "//", with: "/") 
			if path.isEmpty {
				path = "/"
			}
			
			if let scheme = url!.scheme, !scheme.isEmpty {
				var components = URLComponents()
				components.scheme = scheme
				components.host = url?.host
				components.path = path
				url = components.url
			}
		}
		
		urlString = url!.absoluteString
		if urlString.range(of: "&") != nil && urlString.range(of: "?") == nil {
			if let firstURL = URL(string: urlString.components(separatedBy: "&").first!) {
				return [url, firstURL].flatMap({ $0 })
			}
		}
		
		return [url!]
	}
	
	private func _urls(from occurrences: [String]) -> [URL] {
		var urls: [URL] = [ ]
		
		urls += occurrences.flatMap({ (originalURLString) -> [URL]? in
			return self._standardizedURL(from: originalURLString)
		}).joined()
		
		urls = urls.flatMap({ (url) -> URL? in
			if url.host == nil {
				return nil
			}
			
			if url.scheme == nil || url.scheme!.isEmpty {
				var components = URLComponents()
				components.scheme = "http"
				components.host = url.host
				components.path = url.path.isEmpty ? "/" : url.path
				components.query = url.query
				components.fragment = url.fragment
				return components.url
			}
			
			return url
		})
		
		urls = urls.distinct({ ($0 == $1) })
		
		return urls
	}
	
	/// All Occurrences of regex in self.
	public func allOccurrences(ofRegex regex: XURegex) -> [String] {
		return regex.allOccurrences(in: String(self))
	}
	
	/// All Occurrences of regex in self.
	///
	/// Convenience method that takes String as an argument rather than XURegex.
	/// Note that as the rest of these functions, all regex strings are compiled
	/// as caseless by default.
	public func allOccurrences(ofRegex regexString: String) -> [String] {
		return self.allOccurrences(ofRegex: XURegex(pattern: regexString, andOptions: .caseless))
	}
	
	/// Attempts to find all relative URLs in the self.
	public func allRelativeURLs(to baseURL: URL) -> [URL] {
		let regex = XURegex(pattern: "(?i)/[^\\s'\"<>]+", andOptions: XURegexOptions())
		
		var occurrences = regex.allOccurrences(in: String(self))
		occurrences += self.allValues(of: "URL", forRegex: XURegex.URL.sourceSource.regex)
		occurrences += self.allValues(of: "URL", forRegex: XURegex.URL.videoSource.regex)
		occurrences += self.allValues(of: "URL", forRegex: XURegex.URL.iframeSource.regex)
		occurrences += self.allValues(of: "URL", forRegex: "<a[^>]+href=\"(?P<URL>[^\"]+)\"")
		
		occurrences = occurrences.flatMap({ (URLString) -> String? in
			if URLString.hasPrefix("http") || URLString.hasPrefix("//") {
				return nil /* We want just relative URLs. */
			}
			
			return URL(string: URLString, relativeTo: baseURL)?.absoluteString
		})
		
		return self._urls(from: occurrences)
	}
	
	/// Returns all relative URLs to URL created by "/" path and http scheme.
	public func allRelativeURLs(withHost host: String) -> [URL] {
		var components = URLComponents()
		components.scheme = "http"
		components.host = host
		components.path = "/"
		guard let baseURL = components.url else {
			return [ ]
		}
		return self.allRelativeURLs(to: baseURL)
	}
	
	/// Attempts to find all absolute URLs in self. Uses various heuristics to
	/// do so.
	public var allURLs: [URL] {
		let regex = XURegex(pattern: "(?i)(?:(?:[a-z]{2,8}:)?//)?([a-z0-9\\-_]\\.?)*[a-z0-9\\-_]+\\.[a-z0-9\\-_]+(?::\\d+)?(/[^\\(\\)<>\"'\\$\\\\\n\r]*)", andOptions: .caseless)
		var occurrences = regex.allOccurrences(in: self.replacingOccurrences(of: "\r", with: "\n"))
		
		/** Unfortunely some sites idiotically include spaces in the URLs. This is an easy workaround... */
		occurrences += self.allValues(of: "URL", forRegex: "<a[^>]+href=\"(?P<URL>[^\"]+)\"")
		occurrences += self.allValues(of: "URL", forRegex: XURegex.URL.iframeSource.pattern)
		if let ogVideo = self.value(of: "URL", inRegex: XURegex.URL.metaOGVideo.regex) {
			occurrences.append(ogVideo)
		}
		
		return self._urls(from: occurrences)
	}
	
	/// Returns all values of what getRegexVariableNamed would return in self.
	public func allValues(of varName: String, forRegex regex: XURegex) -> [String] {
		return regex.allOccurrences(ofVariableNamed: varName, in: String(self))
	}
	
	/// Returns all values of what getRegexVariableNamed would return in self.
	///
	/// Convenience method that takes String as an argument rather than XURegex.
	/// Note that as the rest of these functions, all regex strings are compiled
	/// as caseless by default.
	public func allValues(of varName: String, forRegex regexString: String) -> [String] {
		return self.allValues(of: varName, forRegex: XURegex(pattern: regexString, andOptions: .caseless))
	}
	
	/// Returns a dictionary of keys and values. This dictionary is created by
	/// mapping all occurrences of the regex in self into (key, value) pairs,
	/// where key is extracted by getting regex variable VARNAME in the match,
	/// value is extracted by getting regex variable VARVALUE in the match.
	///
	/// Example:
	///
	/// (?P<VARNAME>[^=]+)=(?P<VARVALUE>[^&]+)
	public func allVariablePairs(forRegex regex: XURegex) -> [String : String] {
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
	public func allVariablePairs(forRegex regexString: String) -> [String : String] {
		return self.allVariablePairs(forRegex: XURegex(pattern: regexString, andOptions: .caseless))
	}
	
	/// Returns components separated by regex. Works pretty much like separating
	/// components by string or character set, but uses regex. Note that using an
	/// infinite regex will cause the method to call fatalError since it would
	/// lead to an infinite array.
	public func components(separatedByRegex regex: XURegex) -> [String] {
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
	public func components(separatedByRegex regexString: String) -> [String] {
		return self.components(separatedByRegex: XURegex(pattern: regexString, andOptions: .caseless))
	}

	/// The most basic usage - first regex match.
	public func firstOccurrence(ofRegex regex: XURegex) -> String? {
		return regex.firstMatch(in: String(self))
	}
	
	/// The most basic usage - first regex match.
	///
	/// Convenience method that takes String as an argument rather than XURegex.
	/// Note that as the rest of these functions, all regex strings are compiled
	/// as caseless by default.
	public func firstOccurrence(ofRegex regexString: String) -> String? {
		return self.firstOccurrence(ofRegex: XURegex(pattern: regexString, andOptions: .caseless))
	}
	
	/// Iterates regex strings and returns the first one to return a nonnull match.
	///
	/// Convenience method that takes String as an argument rather than XURegex.
	/// Note that as the rest of these functions, all regex strings are compiled
	/// as caseless by default.
	public func firstOccurrence(ofAnyRegex regexStrings: [String]) -> String? {
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
	public func firstOccurrence(ofAnyRegex regexStrings: String...) -> String? {
		return self.firstOccurrence(ofAnyRegex: regexStrings)
	}
	
	
	/// Returns true if any of the regex strings matches self.
	public func matches(anyOfRegexes regexStrings: [String]) -> Bool {
		return regexStrings.contains(where: { self.matches(regex: $0) })
	}
	
	/// Returns true if the regex matches self.
	public func matches(regex: XURegex) -> Bool {
		return self.firstOccurrence(ofRegex: regex) != nil
	}
	
	/// Returns true if the regex matches self.
	///
	/// Convenience method that takes String as an argument rather than XURegex.
	/// Note that as the rest of these functions, all regex strings are compiled
	/// as caseless by default.
	public func matches(regex: String) -> Bool {
		return self.matches(regex: XURegex(pattern: regex, andOptions: .caseless))
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
	public func replacingOccurrences(ofRegex regex: XURegex, with replacement: String) -> String {
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
	public func replacingOccurrences(ofRegex regex: String, with replacement: String) -> String {
		return self.replacingOccurrences(ofRegex: XURegex(pattern: regex, andOptions: .caseless), with: replacement)
	}
	
	/// Returns the value of a variable with name in the regexes. For example:
	/// "data=(?P<DATA>.*)" has a named variable "DATA".
	public func value(of name: String, inRegex regex: XURegex) -> String? {
		return regex.getVariableNamed(name, in: String(self))
	}
	
	/// Returns the value of a variable with name in the regex. For example:
	/// "data=(?P<DATA>.*)" has a named variable "DATA".
	///
	/// Convenience method that takes String as an argument rather than XURegex.
	/// Note that as the rest of these functions, all regex strings are compiled
	/// as caseless by default.
	public func value(of name: String, inRegex regexString: String) -> String? {
		return self.value(of: name, inRegex: XURegex(pattern: regexString, andOptions: .caseless))
	}
	
	/// Returns the value of a variable with name in the regexes. For example:
	/// "data=(?P<DATA>.*)" has a named variable "DATA".
	public func value(of name: String, inRegexes regexStrings: String...) -> String? {
		return self.value(of: name, inRegexes: regexStrings)
	}
	
	/// Returns the value of a variable with name in the regexes. For example:
	/// "data=(?P<DATA>.*)" has a named variable "DATA".
	public func value(of name: String, inRegexes regexStrings: [String]) -> String? {
		for regexString in regexStrings {
			if let match = self.value(of: name, inRegex: regexString) {
				return match
			}
		}
		return nil
	}
	
}

