//
//  NSString+BasicRegex.swift
//  DownieCore
//
//  Created by Charlie Monroe on 10/27/15.
//  Copyright © 2015 Charlie Monroe Software. All rights reserved.
//

import Foundation

public extension XURegex {
	
	public static var alphaNumericRegex: XURegex {
		return XURegex(self.alphaNumericRegexString)
	}
	public static var alphaNumericRegexString: String {
		return "[a-zA-Z0-9]+"
	}
	public static var alphaNumericLowercaseRegex: XURegex {
		return XURegex(self.alphaNumericLowercaseRegexString)
	}
	public static var alphaNumericLowercaseRegexString: String {
		return "[a-z0-9]+"
	}
	public static var alphaNumericUppercaseRegex: XURegex {
		return XURegex(self.alphaNumericUppercaseRegexString)
	}
	public static var alphaNumericUppercaseRegexString: String {
		return "[A-Z0-9]+"
	}
	
	public static var anythingRegex: XURegex {
		return XURegex(self.anythingRegexString)
	}
	public static var anythingRegexString: String {
		return ".*"
	}
	public static var somethingRegex: XURegex {
		return XURegex(self.somethingRegexString)
	}
	public static var somethingRegexString: String {
		return ".*"
	}
	
	public static var hexNumberRegex: XURegex {
		return XURegex(self.hexNumberRegexString)
	}
	public static var hexNumberRegexString: String {
		return "[a-f0-9]+"
	}
	public static var numbersRegex: XURegex {
		return XURegex(self.numbersRegexString)
	}
	public static var numbersRegexString: String {
		return "[0-9]+"
	}
	
	public static var titleH1Regex: XURegex {
		return XURegex(self.titleH1RegexString)
	}
	public static var titleH1RegexString: String {
		return "<h1[^>]*>\\s*(?P<TITLE>.*?)\\s*</h1>"
	}
	public static var titleH2Regex: XURegex {
		return XURegex(self.titleH2RegexString)
	}
	public static var titleH2RegexString: String {
		return "<h2[^>]*>\\s*(?P<TITLE>.*?)\\s*</h2>"
	}
	public static var titleH3Regex: XURegex {
		return XURegex(self.titleH3RegexString)
	}
	public static var titleH3RegexString: String {
		return "<h3[^>]*>\\s*(?P<TITLE>.*?)\\s*</h3>"
	}
	public static var titleMetaTitleRegex: XURegex {
		return XURegex(self.titleMetaTitleRegexString)
	}
	public static var titleMetaTitleRegexString: String {
		return "<meta\\s+(name|property)=\"[a-z:]*title\"\\s+content=\"\\s*(?P<TITLE>.*?)\\s*\""
	}
	public static var titleMetaDescriptionRegex: XURegex {
		return XURegex(self.titleMetaDescriptionRegexString)
	}
	public static var titleMetaDescriptionRegexString: String {
		return "<meta\\s+(name|property)=\"[a-z:]*description\"\\s+content=\"\\s*(?P<TITLE>.*?)\\s*\""
	}
	public static var titleMetaOGTitleRegex: XURegex {
		return XURegex(self.titleMetaOGTitleRegexString)
	}
	public static var titleMetaOGTitleRegexString: String {
		return "<meta[^>]+(property|name)=\"og:title\"[^>]+content=\"\\s*(?P<TITLE>.*?)\\s*\""
	}
	public static var titleTitleRegex: XURegex {
		return XURegex(self.titleTitleRegexString)
	}
	public static var titleTitleRegexString: String {
		return "<title>\\s*(?P<TITLE>.*?)\\s*</title>"
	}
	
	public static var URLMetaOGImageRegex: XURegex {
		return XURegex(self.URLMetaOGImageRegexString)
	}
	public static var URLMetaOGImageRegexString: String {
		return "<meta[^>]+(name|property)=\"og:image\"[^>]+content=\"(?P<URL>[^\"]+)\""
	}
	public static var URLMetaOGVideoRegex: XURegex {
		return XURegex(self.URLMetaOGVideoRegexString)
	}
	public static var URLMetaOGVideoRegexString: String {
		return "<meta[^>]+(name|property)=\"og:video(:url)?\"[^>]+content=\"(?P<URL>[^\"]+)\""
	}
	public static var URLSourceSourceRegex: XURegex {
		return XURegex(self.URLSourceSourceRegexString)
	}
	public static var URLSourceSourceRegexString: String {
		return "<source[^>]+src=[\"'](?P<URL>[^\"']+)[\"']"
	}
	public static var URLVideoPosterRegex: XURegex {
		return XURegex(self.URLVideoPosterRegexString)
	}
	public static var URLVideoPosterRegexString: String {
		return "<video[^>]+poster=\"(?P<URL>[^\"]+)\""
	}
	public static var URLVideoSourceRegex: XURegex {
		return XURegex(self.URLVideoSourceRegexString)
	}
	public static var URLVideoSourceRegexString: String {
		return "<video[^>]+src=\"(?P<URL>[^\"]+)\""
	}
	public static var URLIframeSourceRegex: XURegex {
		return XURegex(self.URLIframeSourceRegexString)
	}
	public static var URLIframeSourceRegexString: String {
		return "<iframe[^>]+src=\"(?P<URL>[^\"]+)\""
	}

	
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
	
}

