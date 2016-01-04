//
//  XULocalizationSupport.swift
//  XUCore
//
//  Created by Charlie Monroe on 11/25/15.
//  Copyright © 2015 Charlie Monroe Software. All rights reserved.
//

import Foundation

private let XULanguageDefaultsKey = "XULanguage"

/// Returns the identifier of current localization.
public func XUCurrentLocalizationLanguageIdentifier() -> String {
	return XULocalizationCenter.sharedCenter.currentLocalizationLanguageIdentifier
}

/// Sets the language identifier as the default langauge.
public func XUSetCurrentLocalizationLanguageIdentifier(identifier: String) {
	XULocalizationCenter.sharedCenter.currentLocalizationLanguageIdentifier = identifier
}

/// Returns a localized string.
public func XULocalizedString(key: String, withLocale language: String? = nil) -> String {
	return XULocalizationCenter.sharedCenter.localizedString(key, withLocale: language ?? XUCurrentLocalizationLanguageIdentifier())
}

/// Returns a formatted string, just like [NSString stringWithFormat:] would return,
/// but the format string gets localized first.
public func XULocalizedFormattedString(format: String, _ arguments: CVarArgType..., withLocale language: String? = nil) -> String {
	return String(format: XULocalizedString(format, withLocale: language), arguments: arguments)
}

/// A new format function which takes `values` and replaces placeholders within `key`
/// with values from `values`.
///
/// Example:
///
///  `key` = @"I have {number} apples."
///  `values` = @{ @"number" : @"2" }
///
///  results in @"I have 2 apples."
///
/// @note `values` can have values other than NSString - -description is called
///            on the values.
public func localizedStringWithFormatValues(key: String, andValues values: [String : AnyObject]) -> String {
	return XULocalizationCenter.sharedCenter.localizedStringWithFormatValues(key, andValues: values)
}


/// This class contains all the necessary methods for localization. You should,
/// however, use the global functions instead, this class is mostly for encapsulation
/// as well as allowing access from Objective-C.
public class XULocalizationCenter: NSObject {
	
	/// Shared instance.
	public static var sharedCenter = XULocalizationCenter()

	/// Cached language dictionaries.
	private var _cachedLanguageDicts: [String : [String : String]] = [ : ]
	
	/// Returns the .lproj bundle for a language. If the language isn't available,
	/// this function falls back to en or Base.
	private func _languageBundleForLanguage(language: String) -> NSBundle? {
		if let URL = NSBundle.mainBundle().URLForResource(language, withExtension: "lproj") {
			return NSBundle(URL: URL)
		}
		
		// Fall back to en or "Base". Just check if the language is "en" so that if
		// the project doesn't contain either, we don't end up in an infinite loop.
		if language == "en" {
			if let bundle = self._languageBundleForLanguage("English") {
				return bundle
			}else if let bundle = self._languageBundleForLanguage("Base") {
				return bundle
			}
		}
		
		return self._languageBundleForLanguage("en")
	}
	
	/// Returns the identifier of current localization.
	public var currentLocalizationLanguageIdentifier: String {
		get {
			if let language = NSUserDefaults.standardUserDefaults().stringForKey(XULanguageDefaultsKey) {
				return language
			}
			
			if let languages = NSUserDefaults.standardUserDefaults().arrayForKey("AppleLanguages") as? [String] {
				if let language = languages.first {
					// The language is often e.g. en-US - get just the first part,
					// unless the language exists for the entire identifier.
					if self._languageBundleForLanguage(language) != nil {
						return language
					}
					return language.componentsSeparatedByString("-").first!
				}
			}
			
			// The language is often e.g. en-US - get just the first part
			return NSLocale.currentLocale().localeIdentifier.componentsSeparatedByString("-").first!
		}
		set(identifier) {
			let defs = NSUserDefaults.standardUserDefaults()
			var languages = defs.arrayForKey("AppleLanguages") as? [String] ?? [ ]
			if let index = languages.indexOf(identifier) {
				languages.removeAtIndex(index)
			}
			languages.insert(identifier, atIndex: 0)
			
			defs.setObject(identifier, forKey: XULanguageDefaultsKey)
			defs.setObject(languages, forKey: "AppleLanguages")
			defs.synchronize()
		}
	}
	
	/// Returns a localized string.
	public func localizedString(key: String, withLocale _language: String? = nil) -> String {
		let language = _language ?? XUCurrentLocalizationLanguageIdentifier()
		
		if key.isEmpty {
			return key
		}
		
		let dict: [String : String]
		if let d = _cachedLanguageDicts[language] {
			dict = d
		}else{
			guard let languageBundle = self._languageBundleForLanguage(language) else {
				return key // No such localization
			}
			
			guard let URL = languageBundle.URLForResource("Localizable", withExtension: "strings", subdirectory: nil, localization: language) else {
				return key
			}
			
			guard let d = NSDictionary(contentsOfURL: URL) as? [String : String] else {
				return key // Invalid format
			}
			
			_cachedLanguageDicts[language] = d
			dict = d
		}
		
		if let value = dict[key] {
			return value
		}
		
		return key
	}
	
	/// A new format function which takes `values` and replaces placeholders within `key`
	/// with values from `values`.
	///
	/// Example:
	///
	///  `key` = @"I have {number} apples."
	///  `values` = @{ @"number" : @"2" }
	///
	///  results in @"I have 2 apples."
	///
	/// @note `values` can have values other than NSString - -description is called
	///            on the values.
	public func localizedStringWithFormatValues(key: String, andValues values: [String : AnyObject]) -> String {
		var localizedString = self.localizedString(key)
		for (key, value) in values {
			let needle = "{\(key)}"
			if localizedString.rangeOfString(needle) == nil {
				XULogStacktrace("Localized string \(localizedString) doesn't have a placeholder for key \(key)")
			}
			
			localizedString = localizedString.stringByReplacingOccurrencesOfString(needle, withString: value.description)
		}
		return localizedString
	}

	
}




