//
//  NSString+BasicRegex.swift
//  DownieCore
//
//  Created by Charlie Monroe on 10/27/15.
//  Copyright © 2015 Charlie Monroe Software. All rights reserved.
//

import Foundation

public extension XURegex {
	
	public struct RegexString {
		
		/// Returns a regex from self.regexString.
		public var regex: XURegex {
			return XURegex(self.regexString)
		}
		
		/// The regex string.
		public let regexString: String
		
		public init(regexString: String) {
			self.regexString = regexString
		}
		
	}
	
	public static let alphaNumeric: RegexString = RegexString(regexString: "[a-zA-Z0-9]+")
	public static let alphaNumericLowercase: RegexString = RegexString(regexString: "[a-z0-9]+")
	public static let alphaNumericUppercase: RegexString = RegexString(regexString: "[A-Z0-9]+")
	
	public static let anything: RegexString = RegexString(regexString: ".*")
	public static let something: RegexString = RegexString(regexString: ".*")
	
	public static let hexNumber: RegexString = RegexString(regexString: "[a-f0-9]+")
	public static let numbers: RegexString = RegexString(regexString: "[0-9]+")

	public static let titleH1: RegexString = RegexString(regexString: "<h1[^>]*>\\s*(?P<TITLE>.*?)\\s*</h1>")
	public static let titleH2: RegexString = RegexString(regexString: "<h2[^>]*>\\s*(?P<TITLE>.*?)\\s*</h2>")
	public static let titleH3: RegexString = RegexString(regexString: "<h3[^>]*>\\s*(?P<TITLE>.*?)\\s*</h3>")
	public static let titleMetaTitle: RegexString = RegexString(regexString: "<meta\\s+(name|property)=\"[a-z:]*title\"\\s+content=\"\\s*(?P<TITLE>.*?)\\s*\"")
	public static let titleMetaDescription: RegexString = RegexString(regexString: "<meta\\s+(name|property)=\"[a-z:]*description\"\\s+content=\"\\s*(?P<TITLE>.*?)\\s*\"")
	public static let titleMetaOGTitle: RegexString = RegexString(regexString: "<meta[^>]+(property|name)=\"og:title\"[^>]+content=\"\\s*(?P<TITLE>.*?)\\s*\"")
	public static let titleTitle: RegexString = RegexString(regexString: "<title>\\s*(?P<TITLE>.*?)\\s*</title>")

	public static let URLMetaOGImage: RegexString = RegexString(regexString: "<meta[^>]+(name|property)=\"og:image\"[^>]+content=\"(?P<URL>[^\"]+)\"")
	public static let URLMetaOGVideo: RegexString = RegexString(regexString: "<meta[^>]+(name|property)=\"og:video(:url)?\"[^>]+content=\"(?P<URL>[^\"]+)\"")
	public static let URLSourceSource: RegexString = RegexString(regexString: "<source[^>]+src=[\"'](?P<URL>[^\"']+)[\"']")
	public static let URLVideoPoster: RegexString = RegexString(regexString: "<video[^>]+poster=\"(?P<URL>[^\"]+)\"")
	public static let URLVideoSource: RegexString = RegexString(regexString: "<video[^>]+src=\"(?P<URL>[^\"]+)\"")
	public static let URLIframeSource: RegexString = RegexString(regexString: "<iframe[^>]+src=\"(?P<URL>[^\"]+)\"")

	
	convenience init(_ pattern: String) {
		self.init(pattern: pattern, andOptions: .None)
	}
	
}

public extension String {
	
	/// Returns a value of a meta HTML field in self. This cannot be achieved by
	/// a single regex, since the name can be either before or after content,
	/// and there is no way to ensure that at least one of the conditions is met.
	public func valueOfMetaFieldNamed(fieldName: String) -> String? {
		return self.getRegexVariableNamed("VALUE", forRegexStrings:
			"<meta[^>]+(itemprop|name|property)=\"\(fieldName)\"[^>]+content=\"(?P<VALUE>[^\"]+)\"",
			"<meta[^>]+content=\"(?P<VALUE>[^\"]+)\"[^>]+(itemprop|name|property)=\"\(fieldName)\""
		)
	}
	
	/// Returns a value of an input HTML field in self. This cannot be achieved by
	/// a single regex, since the name can be either before or after content,
	/// and there is no way to ensure that at least one of the conditions is met.
	public func valueOfInputField(named fieldName: String) -> String? {
		return self.getRegexVariableNamed("VALUE", forRegexStrings:
			"<input[^>]+(name|id)=\"\(fieldName)\"[^>]+value=\"(?P<VALUE>[^\"]+)\"",
		    "<input[^>]+value=\"(?P<VALUE>[^\"]+)\"[^>]+(name|id)=\"\(fieldName)\""
		)
	}
	
}

