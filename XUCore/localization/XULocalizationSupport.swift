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
@inline(__always)
public func XUCurrentLocalizationIdentifierForBundle(bundle: NSBundle) -> String {
	return XULocalizationCenter.sharedCenter.localizationIdentifierForBundle(bundle)
}

/// Sets the language identifier as the default langauge.
@inline(__always)
public func XUSetCurrentLocalizationLanguageIdentifier(identifier: String) {
	XULocalizationCenter.sharedCenter.setCurrentLocalizationIdentifier(identifier)
}

/// Returns a localized string.
@inline(__always)
public func XULocalizedString(key: String, inBundle bundle: NSBundle = XUMainBundle, withLocale language: String? = nil) -> String {
	return XULocalizationCenter.sharedCenter.localizedString(key, withLocale: language ?? XUCurrentLocalizationIdentifierForBundle(bundle), inBundle: bundle)
}

/// Returns a formatted string, just like [NSString stringWithFormat:] would return,
/// but the format string gets localized first.
@inline(__always)
public func XULocalizedFormattedString(format: String, _ arguments: CVarArgType..., withLocale language: String? = nil, inBundle bundle: NSBundle = XUMainBundle) -> String {
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
public final class XULocalizationCenter: NSObject {
	
	/// Shared instance.
	public static var sharedCenter = XULocalizationCenter()

	/// Cached identifiers
	private var _cachedLanguageIdentifiers: [NSBundle : String] = [:]
	
	/// Cached language dictionaries.
	private var _cachedLanguageDicts: [NSBundle: [String : [String : String]]] = [ : ]
	
	/// Lock for modifying _cachedLanguageDicts
	private let _lock: NSLock = NSLock(name: "com.charliemonroe.XULocalization")
	
	/// The language is often e.g. en-US - we need to find the language identifier
	/// that is in that particular bundle.
	private func _identifierFromComposedIdentifier(language: String, inBundle bundle: NSBundle) -> String? {
		// Starting macOS 10.12, there are even more specific identifiers
		// such as zn-Hans-CN. We'll remove one specifier at a time.
		var components: ArraySlice<String> = ArraySlice(language.componentsSeparatedByString("-"))
		while !components.isEmpty {
			let identifier = components.joinWithSeparator("-")
			if self._languageBundleForLanguage(identifier, inBundle: bundle, fallbackToEnglish: false) != nil {
				return identifier
			}
			components = components.dropLast()
		}
		
		/// TODO: Look inside the bundle and find a more specific localization instead?
		
		return nil
	}
	
	/// Returns the .lproj bundle for a language. If the language isn't available,
	/// this function falls back to en or Base.
	private func _languageBundleForLanguage(language: String, inBundle bundle: NSBundle, fallbackToEnglish: Bool = true) -> NSBundle? {
		if let URL = bundle.URLForResource(language, withExtension: "lproj") {
			return NSBundle(URL: URL)
		}
		
		// Fall back to en or "Base". Just check if the language is "en" so that if
		// the project doesn't contain either, we don't end up in an infinite loop.
		if language == "en" {
			if let bundle = self._languageBundleForLanguage("English", inBundle: bundle, fallbackToEnglish: fallbackToEnglish) {
				return bundle
			}else if let bundle = self._languageBundleForLanguage("Base", inBundle: bundle, fallbackToEnglish: fallbackToEnglish) {
				return bundle
			}
		}
		
		if !fallbackToEnglish {
			return nil
		}
		
		return self._languageBundleForLanguage("en", inBundle: bundle, fallbackToEnglish: false)
	}
	
	/// Returns a localization identifier for a particular bundle. The identifier
	/// may be different for each bundle. E.g. one bundle may contain en-US, while
	/// the other just en.
	public func localizationIdentifierForBundle(bundle: NSBundle) -> String {
		if let identifier = _cachedLanguageIdentifiers[bundle] {
			return identifier
		}
		
		if let identifier = NSUserDefaults.standardUserDefaults().stringForKey(XULanguageDefaultsKey) {
			_lock.performLockedBlock {
				self._cachedLanguageIdentifiers[bundle] = identifier
			}
			return identifier
		}
		
		if let languages = NSUserDefaults.standardUserDefaults().arrayForKey("AppleLanguages") as? [String] {
			for language in languages {
				if let identifier = self._identifierFromComposedIdentifier(language, inBundle: bundle) {
					_lock.performLockedBlock {
						self._cachedLanguageIdentifiers[bundle] = identifier
					}
					return identifier
				}
			}
		}
		
		if let identifier = self._identifierFromComposedIdentifier(NSLocale.currentLocale().localeIdentifier, inBundle: bundle) {
			_lock.performLockedBlock {
				self._cachedLanguageIdentifiers[bundle] = identifier
			}
			return identifier
		}
		
		/// This is pure desperation - the bundle is unlikely to have localization
		/// for any requested languages.
		let identifier = NSLocale.currentLocale().localeIdentifier
		_lock.performLockedBlock {
			self._cachedLanguageIdentifiers[bundle] = identifier
		}

		return identifier
	}
	
	/// Set a localization identifier.
	public func setCurrentLocalizationIdentifier(identifier: String) {
		let defs = NSUserDefaults.standardUserDefaults()
		var languages = defs.arrayForKey("AppleLanguages") as? [String] ?? [ ]
		if let index = languages.indexOf(identifier) {
			languages.removeAtIndex(index)
		}
		languages.insert(identifier, atIndex: 0)
		
		defs.setObject(identifier, forKey: XULanguageDefaultsKey)
		defs.setObject(languages, forKey: "AppleLanguages")
		defs.synchronize()
		
		_lock.performLockedBlock {
			self._cachedLanguageIdentifiers = [:]
		}
	}
	
	/// Returns a localized string.
	public func localizedString(key: String, withLocale _language: String? = nil, inBundle bundle: NSBundle = XUMainBundle) -> String {
		let language = _language ?? self.localizationIdentifierForBundle(bundle)
		
		if key.isEmpty {
			return key
		}
		
		/// Perhaps, it's already loaded.
		if let value = _cachedLanguageDicts[bundle]?[language]?[key] {
			return value
		}
		
		/// Now, we know that the string isn't in the localization. There are two
		/// options. Either the localization doesn't contain this phrase, or it
		/// hasn't been loaded yet.
		if let languageDict = _cachedLanguageDicts[bundle]?[language] where !languageDict.isEmpty {
			/// The language has already been loaded -> no point in reloading it.
			return key
		}
		
		_lock.lock()
		defer {
			_lock.unlock()
		}
		
		if _cachedLanguageDicts[bundle] == nil {
			_cachedLanguageDicts[bundle] = [:]
		}
		
		guard let languageBundle = self._languageBundleForLanguage(language, inBundle: bundle) else {
			/// In order to prevent loading for each key, enter a fake entry
			/// into the localization.
			_cachedLanguageDicts[bundle]![language] = ["__XU_LOCALIZATION_PLACEHOLDER__" : ""]
			
			return key // No such localization
		}
		
		guard let URL = languageBundle.URLForResource("Localizable", withExtension: "strings", subdirectory: nil, localization: language), data = NSData(contentsOfURL: URL) else {
			XULog("No '\(language)' localizable strings in bundle \(bundle).")
			
			/// In order to prevent loading for each key, enter a fake entry
			/// into the localization.
			_cachedLanguageDicts[bundle]![language] = ["__XU_LOCALIZATION_PLACEHOLDER__" : ""]
			
			return key
		}
		
		do {
			let object = try NSPropertyListSerialization.propertyListWithData(data, options: .Immutable, format: nil)
			guard let d = object as? [String : String] else {
				XULog("Invalid localization loaded - '\(language)' \(object.dynamicType) \(object).")
				
				/// In order to prevent loading for each key, enter a fake entry
				/// into the localization.
				_cachedLanguageDicts[bundle]![language] = ["__XU_LOCALIZATION_PLACEHOLDER__" : ""]
				
				return key // Invalid format
			}
			
			_cachedLanguageDicts[bundle]![language] = d
			
			return d[key] ?? key
		} catch let err as NSError {
			XULog("Failed to read '\(language)' localizable strings \(err).")
			
			/// In order to prevent loading for each key, enter a fake entry
			/// into the localization.
			_cachedLanguageDicts[bundle]![language] = ["__XU_LOCALIZATION_PLACEHOLDER__" : ""]
			
			return key
		}
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

	/// Returns the identifier of current localization.
	@available(*, deprecated, message="Use the variations with bundle specifications.")
	public var currentLocalizationLanguageIdentifier: String {
		get {
			return self.localizationIdentifierForBundle(XUMainBundle)
		}
		set(identifier) {
			self.setCurrentLocalizationIdentifier(identifier)
		}
	}
	
}





/// Returns the identifier of current localization.
@available(*, deprecated, message="Use XUCurrentLocalizationIdentifierForBundle instead.")
public func XUCurrentLocalizationLanguageIdentifier() -> String {
	return XULocalizationCenter.sharedCenter.currentLocalizationLanguageIdentifier
}
