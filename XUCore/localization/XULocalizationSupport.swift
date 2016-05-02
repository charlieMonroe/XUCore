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
public func XULocalizedString(key: String, inBundle bundle: NSBundle = NSBundle.mainBundle(), withLocale language: String? = nil) -> String {
	return XULocalizationCenter.sharedCenter.localizedString(key, withLocale: language ?? XUCurrentLocalizationLanguageIdentifier(), inBundle: bundle)
}

/// Returns a formatted string, just like [NSString stringWithFormat:] would return,
/// but the format string gets localized first.
public func XULocalizedFormattedString(format: String, _ arguments: CVarArgType..., withLocale language: String? = nil, inBundle bundle: NSBundle = NSBundle.mainBundle()) -> String {
	return String(format: XULocalizedString(format, withLocale: language, inBundle: bundle), arguments: arguments)
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
public func XULocalizedStringWithFormatValues(key: String, andValues values: [String : AnyObject]) -> String {
	return XULocalizationCenter.sharedCenter.localizedStringWithFormatValues(key, andValues: values)
}


/// This class contains all the necessary methods for localization. You should,
/// however, use the global functions instead, this class is mostly for encapsulation
/// as well as allowing access from Objective-C.
public class XULocalizationCenter: NSObject {
	
	/// Shared instance.
	public static var sharedCenter = XULocalizationCenter()

	/// Cached language dictionaries.
	private var _cachedLanguageDicts: [NSBundle: [String : [String : String]]] = [ : ]
	
	/// Returns the .lproj bundle for a language. If the language isn't available,
	/// this function falls back to en or Base.
	private func _languageBundleForLanguage(language: String, inBundle bundle: NSBundle, fallbackToEnglish: Bool = true) -> NSBundle? {
		if let URL = bundle.URLForResource(language, withExtension: "lproj") {
			return NSBundle(URL: URL)
		}
		
		// Fall back to en or "Base". Just check if the language is "en" so that if
		// the project doesn't contain either, we don't end up in an infinite loop.
		if language == "en" {
			if let bundle = self._languageBundleForLanguage("English", inBundle: bundle) {
				return bundle
			}else if let bundle = self._languageBundleForLanguage("Base", inBundle: bundle) {
				return bundle
			}
		}
		
		if !fallbackToEnglish {
			return nil
		}
		
		return self._languageBundleForLanguage("en", inBundle: bundle, fallbackToEnglish: false)
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
					if self._languageBundleForLanguage(language, inBundle: NSBundle.mainBundle(), fallbackToEnglish: false) != nil {
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
	public func localizedString(key: String, withLocale _language: String? = nil, inBundle bundle: NSBundle = NSBundle.mainBundle()) -> String {
		let language = _language ?? XUCurrentLocalizationLanguageIdentifier()
		
		if key.isEmpty {
			return key
		}
		
		if _cachedLanguageDicts[bundle] == nil {
			_cachedLanguageDicts[bundle] = [:]
		}
		
		let dict: [String : String]
		if let d = _cachedLanguageDicts[bundle]![language] {
			dict = d
		}else{
			guard let languageBundle = self._languageBundleForLanguage(language, inBundle: bundle) else {
				return key // No such localization
			}
			
			guard let URL = languageBundle.URLForResource("Localizable", withExtension: "strings", subdirectory: nil, localization: language) else {
				return key
			}
			
			guard let d = NSDictionary(contentsOfURL: URL) as? [String : String] else {
				return key // Invalid format
			}
			
			_cachedLanguageDicts[bundle]![language] = d
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




