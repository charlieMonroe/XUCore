//
//  NSString+XURegexAdditions.swift
//  DownieCore
//
//  Created by Charlie Monroe on 10/27/15.
//  Copyright © 2015 Charlie Monroe Software. All rights reserved.
//

import Foundation

public extension String {
	
	public func firstOccurenceOfRegex(regex: XURegex) -> String? {
		return regex.firstMatchInString(self)
	}
	public func firstOccurenceOfRegexString(regexString: String) -> String? {
		return self.firstOccurenceOfRegex(XURegex(pattern: regexString, andOptions: .Caseless))
	}
	public func allOccurencesOfRegex(regex: XURegex) -> [String] {
		return regex.allOccurencesInString(self)
	}
	public func allOccurencesOfRegexString(regexString: String) -> [String] {
		return self.allOccurencesOfRegex(XURegex(pattern: regexString, andOptions: .Caseless))
	}
	
	public func getRegexVariableNamed(name: String, forRegexString regexString: String) -> String? {
		return self.getRegexVariableNamed(name, forRegex: XURegex(pattern: regexString, andOptions: .Caseless))
	}
	
	public func getRegexVariableNamed(name: String, forRegexStrings regexStrings: String...) -> String? {
		return self.getRegexVariableNamed(name, forRegexStrings: regexStrings)
	}
	public func getRegexVariableNamed(name: String, forRegexStrings regexStrings: [String]) -> String? {
		for regexString in regexStrings {
			if let match = self.getRegexVariableNamed(name, forRegexString: regexString) {
				return match
			}
		}
		return nil
	}
	public func getRegexVariableNamed(name: String, forRegex regex: XURegex) -> String? {
		return regex.getVariableNamed(name, inString: self)
	}
	
	public func allValuesOfVariableNamed(varName: String, forRegexString regexString: String) -> [String] {
		return self.allValuesOfVariableNamed(varName, forRegex: XURegex(pattern: regexString, andOptions: .Caseless))
	}
	public func allValuesOfVariableNamed(varName: String, forRegex regex: XURegex) -> [String] {
		return regex.allOccurencesOfVariableNamed(varName, inString: self)
	}
	
	public func allVariablePairsForRegex(regex: XURegex) -> [String:String] {
		return regex.allVariablePairsInString(self)
	}
	public func allVariablePairsForRegexString(regexString: String) -> [String:String] {
		return self.allVariablePairsForRegex(XURegex(pattern: regexString, andOptions: .Caseless))
	}
	
	public var allURLs: [NSURL] {
		var URLs: [NSURL] = [ ]
		let regex = XURegex(pattern: "(?i)(?:(?:[a-z]{2,8}:)?//)?([a-z0-9\\-_]\\.?)*[a-z0-9\\-_]+\\.[a-z0-9\\-_]+(?::\\d+)?(/[^\\(\\)<>\"'\\$\\\\\n]*)", andOptions: .Caseless)
		var occurences = regex.allOccurencesInString(self)
		
		/** Unfortunely some sites idiotically include spaces in the URLs. This is an easy workaround... */
		occurences += self.allValuesOfVariableNamed("URL", forRegexString: "<a[^>]+href=\"(?P<URL>[^\"]+)\"")
		occurences += self.allValuesOfVariableNamed("URL", forRegexString: XURegex.URLIframeSourceRegexString)
		if let ogVideo = self.getRegexVariableNamed("URL", forRegex: XURegex.URLMetaOGVideoRegex) {
			occurences.append(ogVideo)
		}
		
		URLs += occurences.filterMap({ (var URLString) -> NSURL? in
			if URLString.hasPrefix("//") {
				URLString = "http:" + URLString
			}else if !URLString.hasPrefix("http") && !URLString.hasPrefix("rtmp") && !URLString.hasPrefix("rtme") {
				URLString = "http://" + URLString
			}
			
			if URLString.rangeOfString("&amp;") != nil {
				URLString = URLString.HTMLUnescapedString()
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
				URL = NSURL(string: URLString.HTMLUnescapedString())
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
					URLs.append(firstURL)
				}
			}
			
			return URL
		})
		
		URLs = URLs.distinct({ $0.isEqual($1) })
		URLs = URLs.filterMap({ (URL) -> NSURL? in
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
	
	public func allRelativeURLsToURL(baseURL: NSURL) -> [NSURL] {
		var URLs: [NSURL] = [ ]
		
		let regex = XURegex(pattern: "(?i)/[^\\s'\"<>]+", andOptions: .None)
		
		var occurences = regex.allOccurencesInString(self)
		occurences += self.allValuesOfVariableNamed("URL", forRegexString: XURegex.URLSourceSourceRegexString)
		occurences += self.allValuesOfVariableNamed("URL", forRegexString: XURegex.URLVideoSourceRegexString)
		occurences += self.allValuesOfVariableNamed("URL", forRegexString: XURegex.URLIframeSourceRegexString)
		occurences += self.allValuesOfVariableNamed("URL", forRegexString: "<a[^>]+href=\"(?P<URL>[^\"]+)\"")
		
		URLs += occurences.filterMap({ (URLString) -> NSURL? in
			if URLString.hasPrefix("http") || URLString.hasPrefix("//") {
				return nil /* We want just relative URLs. */
			}
			
			let URL = NSURL(string: URLString, relativeToURL: baseURL)
			return URL
		})
		
		return URLs.distinct({ $0.isEqual($1) })
	}
	
	public func allRelativeURLsWithHost(host: String) -> [NSURL] {
		guard let baseURL = NSURL(scheme: "http", host: host, path: "/") else {
			return [ ]
		}
		return self.allRelativeURLsToURL(baseURL)
	}
	
	public func matchesAnyOfRegexStrings(regexpStrings: [String]) -> Bool {
		return regexpStrings.any({ self.matchesRegexString($0) })
	}
	public func matchesRegex(regexp: XURegex) -> Bool {
		return self.firstOccurenceOfRegex(regexp) != nil
	}
	public func matchesRegexString(regexpString: String) -> Bool {
		return self.matchesRegex(XURegex(pattern: regexpString, andOptions: .Caseless))
	}
	
	public func valueOfMetaFieldNamed(fieldName: String) -> String? {
		return self.getRegexVariableNamed("VALUE", forRegexStrings:
						"<meta[^>]+(itemprop|name|property)=\"\(fieldName)\"[^>]+content=\"(?P<VALUE>[^\"]+)\"",
						"<meta[^>]+content=\"(?P<VALUE>[^\"]+)\"[^>]+(itemprop|name|property)=\"\(fieldName)\""
			)
		
	}
	
}

