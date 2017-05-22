//
//  String+BasicRegex.swift
//  XUCore
//
//  Created by Charlie Monroe on 10/27/15.
//  Copyright © 2015 Charlie Monroe Software. All rights reserved.
//

import Foundation

/// Protocol defining a predefined regex family. See below.
public protocol XURegexFamily {
	
	/// Pattern of the regex.
	var pattern: String { get }
	
	/// The underlying XURegex value.
	var regex: XURegex { get }
	
}

/// Extended XURegexFamily with a variable.
public protocol XURegexFamilyWithVariable: XURegexFamily {
	
	/// Name of the variable in the regex.
	static var variableName: String { get }
	
}

public extension XURegexFamily {
	
	/// Returns a regex from self.pattern. Always caseless.
	public var regex: XURegex {
		return XURegex(pattern: self.pattern, andOptions: .caseless)
	}
	
	/// Compatibility with the previous XURegex.pattern.
	@available(*, deprecated, renamed: "pattern")
	public var regexString: String {
		return self.pattern
	}
	
}

public extension XURegexFamilyWithVariable {
	
	/// Value of the variable in the `string`. Equivalent to
	/// string.value(of: type(of: self).variableName, inRegex: self.regex)
	public func value(in string: String) -> String? {
		return string.value(of: type(of: self).variableName, inRegex: self.regex)
	}
	
}


/// This struct gathers some basic regex strings for convenience.
public extension XURegex {
	
	/// A simple structure for defining basic regexes.
	public struct RegexString: XURegexFamily {
		
		/// Pattern.
		public let pattern: String
		
		/// Designated initializer.
		public init(pattern: String) {
			self.pattern = pattern
		}
		
	}
	
	/// This struct gathers a family of regexes that contain a variable named
	/// "URL".
	public struct URL: XURegexFamilyWithVariable {
		
		/// Name of the variable within these regexes.
		public static let variableName: String = "URL"
		
		public static let imageSource: XURegex.URL = XURegex.URL(pattern: "<img[^>]+src=[\"'](?P<URL>[^\"']+)[\"']")
		public static let metaOGImage: XURegex.URL = XURegex.URL(pattern: "<meta[^>]+(name|property)=\"og:image\"[^>]+content=\"(?P<URL>[^\"]+)\"")
		public static let metaOGVideo: XURegex.URL = XURegex.URL(pattern: "<meta[^>]+(name|property)=\"og:video(:url)?\"[^>]+content=\"(?P<URL>[^\"]+)\"")
		public static let sourceSource: XURegex.URL = XURegex.URL(pattern: "<source[^>]+src=[\"'](?P<URL>[^\"']+)[\"']")
		public static let videoPoster: XURegex.URL = XURegex.URL(pattern: "<video[^>]+poster=\"(?P<URL>[^\"]+)\"")
		public static let videoSource: XURegex.URL = XURegex.URL(pattern: "<video[^>]+src=\"(?P<URL>[^\"]+)\"")
		public static let iframeSource: XURegex.URL = XURegex.URL(pattern: "<iframe[^>]+src=\"(?P<URL>[^\"]+)\"")

		
		/// Pattern.
		public let pattern: String
		
		/// Designated initializer.
		public init(pattern: String) {
			self.pattern = pattern
		}

	}
	
	/// This struct gathers all RegexString structs that contain a variable named
	/// "TITLE".
	public struct Title: XURegexFamilyWithVariable {
		
		/// Name of the variable within these regexes.
		public static let variableName: String = "TITLE"

		public static let h1: XURegex.Title = XURegex.Title(pattern: "<h1[^>]*>\\s*(?P<TITLE>.*?)\\s*</h1>")
		public static let h2: XURegex.Title = XURegex.Title(pattern: "<h2[^>]*>\\s*(?P<TITLE>.*?)\\s*</h2>")
		public static let h3: XURegex.Title = XURegex.Title(pattern: "<h3[^>]*>\\s*(?P<TITLE>.*?)\\s*</h3>")
		public static let h4: XURegex.Title = XURegex.Title(pattern: "<h4[^>]*>\\s*(?P<TITLE>.*?)\\s*</h4>")
		public static let h5: XURegex.Title = XURegex.Title(pattern: "<h5[^>]*>\\s*(?P<TITLE>.*?)\\s*</h5>")
		public static let metaTitle: XURegex.Title = XURegex.Title(pattern: "<meta\\s+(name|property)=\"[a-z:]*title\"\\s+content=\"\\s*(?P<TITLE>.*?)\\s*\"")
		public static let metaDescription: XURegex.Title = XURegex.Title(pattern: "<meta\\s+(name|property)=\"[a-z:]*description\"\\s+content=\"\\s*(?P<TITLE>.*?)\\s*\"")
		public static let metaOGTitle: XURegex.Title = XURegex.Title(pattern: "<meta[^>]+(property|name)=\"og:title\"[^>]+content=\"\\s*(?P<TITLE>.*?)\\s*\"")
		public static let title: XURegex.Title = XURegex.Title(pattern: "<title>\\s*(?P<TITLE>.*?)\\s*</title>")
		
		
		/// Pattern.
		public let pattern: String
		
		/// Designated initializer.
		public init(pattern: String) {
			self.pattern = pattern
		}

	}
		
	public static let alphaNumeric: RegexString = RegexString(pattern: "[a-zA-Z0-9]+")
	public static let alphaNumericLowercase: RegexString = RegexString(pattern: "[a-z0-9]+")
	public static let alphaNumericUppercase: RegexString = RegexString(pattern: "[A-Z0-9]+")
	
	public static let anything: RegexString = RegexString(pattern: ".*")
	public static let something: RegexString = RegexString(pattern: ".+")
	
	public static let hexNumber: RegexString = RegexString(pattern: "[a-f0-9]+")
	public static let numbers: RegexString = RegexString(pattern: "[0-9]+")
	
}

public extension String {
	
	/// Returns a value of a data-`fieldName` HTML field in self. This is 
	/// a convenience method so that a special regex doesn't have to be created
	/// each time. Note that this method does not work property when the value
	/// contains quotes.
	public func value(ofDataFieldNamed fieldName: String) -> String? {
		return self.value(of: "VALUE", inRegexes:
			"data-\(fieldName)=\"(?P<VALUE>[^\"]+)\"",
			"data-\(fieldName)='(?P<VALUE>[^']+)'"
		)
	}
	
	/// Returns a value of a meta HTML field in self. This cannot be achieved by
	/// a single regex, since the name can be either before or after content,
	/// and there is no way to ensure that at least one of the conditions is met.
	public func value(ofMetaFieldNamed fieldName: String) -> String? {
		return self.value(of: "VALUE", inRegexes:
			"<meta[^>]+(itemprop|name|property)=\"\(fieldName)\"[^>]+content=\"(?P<VALUE>[^\"]+)\"",
			"<meta[^>]+content=\"(?P<VALUE>[^\"]+)\"[^>]+(itemprop|name|property)=\"\(fieldName)\""
		)
	}
	
	/// Returns a value of an input HTML field in self. This cannot be achieved by
	/// a single regex, since the name can be either before or after content,
	/// and there is no way to ensure that at least one of the conditions is met.
	public func value(ofInputFieldNamed fieldName: String) -> String? {
		return self.value(of: "VALUE", inRegexes:
			"<input[^>]+(name|id)=\"\(fieldName)\"[^>]+value=\"(?P<VALUE>[^\"]+)\"",
		    "<input[^>]+value=\"(?P<VALUE>[^\"]+)\"[^>]+(name|id)=\"\(fieldName)\""
		)
	}
	
}

