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
		var urlString = originalURLString
		if urlString.hasPrefix("//") {
			urlString = "http:" + urlString
		}else if !urlString.hasPrefix("http") && !urlString.hasPrefix("rtmp") && !urlString.hasPrefix("rtme") {
			urlString = "http://" + urlString
		}
		
		if urlString.range(of: "&amp;") != nil {
			urlString = urlString.HTMLUnescapedString
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
			url = URL(string: urlString.HTMLUnescapedString)
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
	
	fileprivate func _URLStringOccurrencesToNSURLs(_ occurrences: [String]) -> [URL] {
		var urls: [URL] = [ ]
		
		urls += occurrences.flatMap({ (originalURLString) -> [URL]? in
			return self._standardizedURLFromURLString(originalURLString)
		}).joined()
		
		urls = urls.distinct({ ($0 == $1) })
		urls = urls.flatMap({ (url) -> URL? in
			if url.host == nil {
				return nil
			}
			
			if url.scheme == nil || url.scheme!.isEmpty {
				var components = URLComponents()
				components.scheme = "http"
				components.host = url.host
				components.path = url.path.isEmpty ? "/" : url.path
				return components.url
			}
			
			return url
		})
		
		return urls
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

