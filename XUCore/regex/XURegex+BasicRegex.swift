//
//  String+BasicRegex.swift
//  XUCore
//
//  Created by Charlie Monroe on 10/27/15.
//  Copyright © 2015 Charlie Monroe Software. All rights reserved.
//

import Foundation

/// This struct gathers some basic regex strings for convenience.
public extension XURegex {
	
	public struct RegexString {
		
		/// Returns a regex from self.regexString. Always caseless.
		public var regex: XURegex {
			return XURegex(pattern: self.regexString, andOptions: .caseless)
		}
		
		/// The regex string.
		public let regexString: String
		
		public init(regexString: String) {
			self.regexString = regexString
		}
		
	}
	
	/// This struct gathers all RegexString structs that contain a variable named
	/// "URL".
	public struct URL {
		
		/// Name of the variable within these regexes.
		public static let variableName: String = "URL"
		
		public static let imageSource: RegexString = RegexString(regexString: "<img[^>]+src=[\"'](?P<URL>[^\"']+)[\"']")
		public static let metaOGImage: RegexString = RegexString(regexString: "<meta[^>]+(name|property)=\"og:image\"[^>]+content=\"(?P<URL>[^\"]+)\"")
		public static let metaOGVideo: RegexString = RegexString(regexString: "<meta[^>]+(name|property)=\"og:video(:url)?\"[^>]+content=\"(?P<URL>[^\"]+)\"")
		public static let sourceSource: RegexString = RegexString(regexString: "<source[^>]+src=[\"'](?P<URL>[^\"']+)[\"']")
		public static let videoPoster: RegexString = RegexString(regexString: "<video[^>]+poster=\"(?P<URL>[^\"]+)\"")
		public static let videoSource: RegexString = RegexString(regexString: "<video[^>]+src=\"(?P<URL>[^\"]+)\"")
		public static let iframeSource: RegexString = RegexString(regexString: "<iframe[^>]+src=\"(?P<URL>[^\"]+)\"")

	}
	
	/// This struct gathers all RegexString structs that contain a variable named
	/// "TITLE".
	public struct Title {
		
		/// Name of the variable within these regexes.
		public static let variableName: String = "TITLE"

		public static let h1: RegexString = RegexString(regexString: "<h1[^>]*>\\s*(?P<TITLE>.*?)\\s*</h1>")
		public static let h2: RegexString = RegexString(regexString: "<h2[^>]*>\\s*(?P<TITLE>.*?)\\s*</h2>")
		public static let h3: RegexString = RegexString(regexString: "<h3[^>]*>\\s*(?P<TITLE>.*?)\\s*</h3>")
		public static let h4: RegexString = RegexString(regexString: "<h4[^>]*>\\s*(?P<TITLE>.*?)\\s*</h4>")
		public static let h5: RegexString = RegexString(regexString: "<h5[^>]*>\\s*(?P<TITLE>.*?)\\s*</h5>")
		public static let metaTitle: RegexString = RegexString(regexString: "<meta\\s+(name|property)=\"[a-z:]*title\"\\s+content=\"\\s*(?P<TITLE>.*?)\\s*\"")
		public static let metaDescription: RegexString = RegexString(regexString: "<meta\\s+(name|property)=\"[a-z:]*description\"\\s+content=\"\\s*(?P<TITLE>.*?)\\s*\"")
		public static let metaOGTitle: RegexString = RegexString(regexString: "<meta[^>]+(property|name)=\"og:title\"[^>]+content=\"\\s*(?P<TITLE>.*?)\\s*\"")
		public static let title: RegexString = RegexString(regexString: "<title>\\s*(?P<TITLE>.*?)\\s*</title>")
	}
		
	public static let alphaNumeric: RegexString = RegexString(regexString: "[a-zA-Z0-9]+")
	public static let alphaNumericLowercase: RegexString = RegexString(regexString: "[a-z0-9]+")
	public static let alphaNumericUppercase: RegexString = RegexString(regexString: "[A-Z0-9]+")
	
	public static let anything: RegexString = RegexString(regexString: ".*")
	public static let something: RegexString = RegexString(regexString: ".+")
	
	public static let hexNumber: RegexString = RegexString(regexString: "[a-f0-9]+")
	public static let numbers: RegexString = RegexString(regexString: "[0-9]+")
	
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

