//
//  NSString+XURegexAdditions.swift
//  DownieCore
//
//  Created by Charlie Monroe on 10/27/15.
//  Copyright © 2015 Charlie Monroe Software. All rights reserved.
//

import Foundation

public extension String {
	
	private func _standardizedURLFromURLString(originalURLString: String) -> [NSURL]? {
		var URLString = originalURLString
		if URLString.hasPrefix("//") {
			URLString = "http:" + URLString
		}else if !URLString.hasPrefix("http") && !URLString.hasPrefix("rtmp") && !URLString.hasPrefix("rtme") {
			URLString = "http://" + URLString
		}
		
		if URLString.rangeOfString("&amp;") != nil {
			URLString = URLString.HTMLUnescapedString
		}
		
		if let decoded = URLString.stringByRemovingPercentEncoding {
			if URLString.rangeOfString("%3D") != nil && NSURL(string: decoded) != nil {
				URLString = decoded
			}
		}
		
		if URLString.rangeOfString(" ") != nil {
			URLString = URLString.stringByReplacingOccurrencesOfString(" ", withString: "%20")
		}
		
		if URLString.componentsSeparatedByString("#").count > 2 {
			URLString = URLString.stringByReplacingOccurrencesOfString("#", withString: "%23")
		}
		
		var URL = NSURL(string: URLString)
		if URL == nil {
			if let decoded = URLString.stringByRemovingPercentEncoding {
				URL = NSURL(string: decoded)
			}
		}
		
		if URL == nil {
			URL = NSURL(string: URLString.HTMLUnescapedString)
		}
		
		if URL == nil {
			return nil
		}
		
		if URL!.path?.rangeOfString("//") != nil {
			var path = URL!.path?.stringByReplacingOccurrencesOfString("//", withString: "/") ?? "/"
			if path.characters.count == 0 {
				path = "/"
			}
			
			if URL!.scheme.characters.count > 0 {
				URL = NSURL(scheme: URL!.scheme, host: URL!.host, path: path)
			}
		}
		
		URLString = URL!.absoluteString
		if URLString.rangeOfString("&") != nil && URLString.rangeOfString("?") == nil {
			if let firstURL = NSURL(string: URLString.componentsSeparatedByString("&").first!) {
				[URL, firstURL]
			}
		}
		
		return [URL!]
	}
	
	private func _URLStringOccurrencesToNSURLs(occurrences: [String]) -> [NSURL] {
		var URLs: [NSURL] = [ ]
		
		URLs += occurrences.flatMap({ (originalURLString) -> [NSURL]? in
			return self._standardizedURLFromURLString(originalURLString)
		}).flatten()
		
		URLs = URLs.distinct({ $0.isEqual($1) })
		URLs = URLs.flatMap({ (URL) -> NSURL? in
			if URL.host == nil {
				return nil
			}
			if URL.path == nil {
				return nil
			}
			
			if URL.scheme.characters.count == 0 {
				return NSURL(scheme: "http", host: URL.host, path: URL.path!.characters.count == 0 ? "/" : URL.path!)
			}
			
			return URL
		})
		
		return URLs
	}
	
	/// All Occurrences of regex in self.
	public func allOccurrencesOfRegex(regex: XURegex) -> [String] {
		return regex.allOccurrencesInString(self)
	}
	
	/// All Occurrences of regex in self.
	///
	/// Convenience method that takes String as an argument rather than XURegex.
	/// Note that as the rest of these functions, all regex strings are compiled
	/// as caseless by default.
	public func allOccurrencesOfRegexString(regexString: String) -> [String] {
		return self.allOccurrencesOfRegex(XURegex(pattern: regexString, andOptions: .Caseless))
	}
	
	/// Attempts to find all relative URLs in the self.
	public func allRelativeURLsToURL(baseURL: NSURL) -> [NSURL] {
		let regex = XURegex(pattern: "(?i)/[^\\s'\"<>]+", andOptions: .None)
		
		var occurrences = regex.allOccurrencesInString(self)
		occurrences += self.allValuesOfVariableNamed("URL", forRegexString: XURegex.URLSourceSource.regexString)
		occurrences += self.allValuesOfVariableNamed("URL", forRegexString: XURegex.URLVideoSource.regexString)
		occurrences += self.allValuesOfVariableNamed("URL", forRegexString: XURegex.URLIframeSource.regexString)
		occurrences += self.allValuesOfVariableNamed("URL", forRegexString: "<a[^>]+href=\"(?P<URL>[^\"]+)\"")
		
		occurrences = occurrences.flatMap({ (URLString) -> String? in
			if URLString.hasPrefix("http") || URLString.hasPrefix("//") {
				return nil /* We want just relative URLs. */
			}
			
			return NSURL(string: URLString, relativeToURL: baseURL)?.absoluteString
		})
		
		return self._URLStringOccurrencesToNSURLs(occurrences)
	}
	
	/// Returns all relative URLs to URL created by "/" path and http scheme.
	public func allRelativeURLsWithHost(host: String) -> [NSURL] {
		guard let baseURL = NSURL(scheme: "http", host: host, path: "/") else {
			return [ ]
		}
		return self.allRelativeURLsToURL(baseURL)
	}
	
	/// Attempts to find all absolute URLs in self. Uses various heuristics to
	/// do so.
	public var allURLs: [NSURL] {
		let regex = XURegex(pattern: "(?i)(?:(?:[a-z]{2,8}:)?//)?([a-z0-9\\-_]\\.?)*[a-z0-9\\-_]+\\.[a-z0-9\\-_]+(?::\\d+)?(/[^\\(\\)<>\"'\\$\\\\\n\r]*)", andOptions: .Caseless)
		var occurrences = regex.allOccurrencesInString(self.stringByReplacingOccurrencesOfString("\r", withString: "\n"))
		
		/** Unfortunely some sites idiotically include spaces in the URLs. This is an easy workaround... */
		occurrences += self.allValuesOfVariableNamed("URL", forRegexString: "<a[^>]+href=\"(?P<URL>[^\"]+)\"")
		occurrences += self.allValuesOfVariableNamed("URL", forRegexString: XURegex.URLIframeSource.regexString)
		if let ogVideo = self.getRegexVariableNamed("URL", forRegex: XURegex.URLMetaOGVideo.regex) {
			occurrences.append(ogVideo)
		}
		
		return self._URLStringOccurrencesToNSURLs(occurrences)
	}
	
	/// Returns all values of what getRegexVariableNamed would return in self.
	public func allValuesOfVariableNamed(varName: String, forRegex regex: XURegex) -> [String] {
		return regex.allOccurrencesOfVariableNamed(varName, inString: self)
	}
	
	/// Returns all values of what getRegexVariableNamed would return in self.
	///
	/// Convenience method that takes String as an argument rather than XURegex.
	/// Note that as the rest of these functions, all regex strings are compiled
	/// as caseless by default.
	public func allValuesOfVariableNamed(varName: String, forRegexString regexString: String) -> [String] {
		return self.allValuesOfVariableNamed(varName, forRegex: XURegex(pattern: regexString, andOptions: .Caseless))
	}
	
	/// Returns a dictionary of keys and values. This dictionary is created by
	/// mapping all occurrences of the regex in self into (key, value) pairs,
	/// where key is extracted by getting regex variable VARNAME in the match,
	/// value is extracted by getting regex variable VARVALUE in the match.
	///
	/// Example:
	///
	/// (?P<VARNAME>[^=]+)=(?P<VARVALUE>[^&]+)
	public func allVariablePairsForRegex(regex: XURegex) -> [String : String] {
		return regex.allVariablePairsInString(self)
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
	public func allVariablePairsForRegexString(regexString: String) -> [String : String] {
		return self.allVariablePairsForRegex(XURegex(pattern: regexString, andOptions: .Caseless))
	}
	
	/// The most basic usage - first regex match.
	public func firstOccurrenceOfRegex(regex: XURegex) -> String? {
		return regex.firstMatchInString(self)
	}
	
	/// The most basic usage - first regex match.
	///
	/// Convenience method that takes String as an argument rather than XURegex.
	/// Note that as the rest of these functions, all regex strings are compiled
	/// as caseless by default.
	public func firstOccurrenceOfRegexString(regexString: String) -> String? {
		return self.firstOccurrenceOfRegex(XURegex(pattern: regexString, andOptions: .Caseless))
	}
	
	/// Iterates regex strings and returns the first one to return a nonnull match.
	///
	/// Convenience method that takes String as an argument rather than XURegex.
	/// Note that as the rest of these functions, all regex strings are compiled
	/// as caseless by default.
	public func firstOccurrenceOfRegexStrings(regexStrings: [String]) -> String? {
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
	public func firstOccurrenceOfRegexStrings(regexStrings: String...) -> String? {
		return self.firstOccurrenceOfRegexStrings(regexStrings)
	}
	
	
	/// Returns the value of a variable with name in the regexes. For example:
	/// "data=(?P<DATA>.*)" has a named variable "DATA".
	public func getRegexVariableNamed(name: String, forRegex regex: XURegex) -> String? {
		return regex.getVariableNamed(name, inString: self)
	}
	
	/// Returns the value of a variable with name in the regex. For example:
	/// "data=(?P<DATA>.*)" has a named variable "DATA".
	///
	/// Convenience method that takes String as an argument rather than XURegex.
	/// Note that as the rest of these functions, all regex strings are compiled
	/// as caseless by default.
	public func getRegexVariableNamed(name: String, forRegexString regexString: String) -> String? {
		return self.getRegexVariableNamed(name, forRegex: XURegex(pattern: regexString, andOptions: .Caseless))
	}
	
	/// Returns the value of a variable with name in the regexes. For example:
	/// "data=(?P<DATA>.*)" has a named variable "DATA".
	public func getRegexVariableNamed(name: String, forRegexStrings regexStrings: String...) -> String? {
		return self.getRegexVariableNamed(name, forRegexStrings: regexStrings)
	}
	
	/// Returns the value of a variable with name in the regexes. For example:
	/// "data=(?P<DATA>.*)" has a named variable "DATA".
	public func getRegexVariableNamed(name: String, forRegexStrings regexStrings: [String]) -> String? {
		for regexString in regexStrings {
			if let match = self.getRegexVariableNamed(name, forRegexString: regexString) {
				return match
			}
		}
		return nil
	}
	
	/// Returns true if any of the regex strings matches self.
	public func matchesAnyOfRegexStrings(regexStrings: [String]) -> Bool {
		return regexStrings.contains({ self.matchesRegexString($0) })
	}
	
	/// Returns true if the regex matches self.
	public func matchesRegex(regex: XURegex) -> Bool {
		return self.firstOccurrenceOfRegex(regex) != nil
	}
	
	/// Returns true if the regex matches self.
	///
	/// Convenience method that takes String as an argument rather than XURegex.
	/// Note that as the rest of these functions, all regex strings are compiled
	/// as caseless by default.
	public func matchesRegexString(regexString: String) -> Bool {
		return self.matchesRegex(XURegex(pattern: regexString, andOptions: .Caseless))
	}
	
}

