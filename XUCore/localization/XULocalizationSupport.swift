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
public func XUCurrentLocalizationIdentifierForBundle(_ bundle: Bundle) -> String {
	return XULocalizationCenter.sharedCenter.localizationIdentifierForBundle(bundle)
}

/// Sets the language identifier as the default langauge.
@inline(__always)
public func XUSetCurrentLocalizationLanguageIdentifier(_ identifier: String) {
	XULocalizationCenter.sharedCenter.setCurrentLocalizationIdentifier(identifier)
}

/// Returns a localized string.
@inline(__always)
public func XULocalizedString(_ key: String, inBundle bundle: Bundle = XUMainBundle, withLocale language: String? = nil) -> String {
	return XULocalizationCenter.sharedCenter.localizedString(key, withLocale: language ?? XUCurrentLocalizationIdentifierForBundle(bundle), inBundle: bundle)
}

/// Returns a formatted string, just like [NSString stringWithFormat:] would return,
/// but the format string gets localized first.
@inline(__always)
public func XULocalizedFormattedString(_ format: String, _ arguments: CVarArg..., withLocale language: String? = nil, inBundle bundle: Bundle = XUMainBundle) -> String {
	return String(format: XULocalizedString(format, inBundle: bundle, withLocale: language), arguments: arguments)
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
public func XULocalizedStringWithFormatValues(_ key: String, andValues values: [String : AnyObject]) -> String {
	return XULocalizationCenter.sharedCenter.localizedStringWithFormatValues(key, andValues: values)
}


/// This class contains all the necessary methods for localization. You should,
/// however, use the global functions instead, this class is mostly for encapsulation
/// as well as allowing access from Objective-C.
public final class XULocalizationCenter: NSObject {
	
	/// Shared instance.
	public static var sharedCenter = XULocalizationCenter()

	/// Cached identifiers
	fileprivate var _cachedLanguageIdentifiers: [Bundle : String] = [:]
	
	/// Cached language dictionaries.
	fileprivate var _cachedLanguageDicts: [Bundle: [String : [String : String]]] = [ : ]
	
	/// Lock for modifying _cachedLanguageDicts
	fileprivate let _lock: NSLock = NSLock(name: "com.charliemonroe.XULocalization")
	
	/// The language is often e.g. en-US - we need to find the language identifier
	/// that is in that particular bundle.
	fileprivate func _identifierFromComposedIdentifier(_ language: String, inBundle bundle: Bundle) -> String? {
		// Starting macOS 10.12, there are even more specific identifiers
		// such as zn-Hans-CN. We'll remove one specifier at a time.
		var components: ArraySlice<String> = ArraySlice(language.components(separatedBy: "-"))
		while !components.isEmpty {
			let identifier = components.joined(separator: "-")
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
	fileprivate func _languageBundleForLanguage(_ language: String, inBundle bundle: Bundle, fallbackToEnglish: Bool = true) -> Bundle? {
		if let URL = bundle.url(forResource: language, withExtension: "lproj") {
			return Bundle(url: URL)
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
	public func localizationIdentifierForBundle(_ bundle: Bundle) -> String {
		if let identifier = _cachedLanguageIdentifiers[bundle] {
			return identifier
		}
		
		if let identifier = UserDefaults.standard.string(forKey: XULanguageDefaultsKey) {
			_lock.performLockedBlock {
				self._cachedLanguageIdentifiers[bundle] = identifier
			}
			return identifier
		}
		
		if let languages = UserDefaults.standard.array(forKey: "AppleLanguages") as? [String] {
			for language in languages {
				if let identifier = self._identifierFromComposedIdentifier(language, inBundle: bundle) {
					_lock.performLockedBlock {
						self._cachedLanguageIdentifiers[bundle] = identifier
					}
					return identifier
				}
			}
		}
		
		if let identifier = self._identifierFromComposedIdentifier(Locale.current.identifier, inBundle: bundle) {
			_lock.performLockedBlock {
				self._cachedLanguageIdentifiers[bundle] = identifier
			}
			return identifier
		}
		
		/// This is pure desperation - the bundle is unlikely to have localization
		/// for any requested languages.
		let identifier = Locale.current.identifier
		_lock.performLockedBlock {
			self._cachedLanguageIdentifiers[bundle] = identifier
		}

		return identifier
	}
	
	/// Set a localization identifier.
	public func setCurrentLocalizationIdentifier(_ identifier: String) {
		let defs = UserDefaults.standard
		var languages = defs.array(forKey: "AppleLanguages") as? [String] ?? [ ]
		if let index = languages.index(of: identifier) {
			languages.remove(at: index)
		}
		languages.insert(identifier, at: 0)
		
		defs.set(identifier, forKey: XULanguageDefaultsKey)
		defs.set(languages, forKey: "AppleLanguages")
		defs.synchronize()
		
		_lock.performLockedBlock {
			self._cachedLanguageIdentifiers = [:]
		}
	}
	
	/// Returns a localized string.
	public func localizedString(_ key: String, withLocale _language: String? = nil, inBundle bundle: Bundle = XUMainBundle) -> String {
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
		if let languageDict = _cachedLanguageDicts[bundle]?[language] , !languageDict.isEmpty {
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
		
		guard let URL = languageBundle.url(forResource: "Localizable", withExtension: "strings", subdirectory: nil, localization: language), let data = try? Data(contentsOf: URL) else {
			XULog("No '\(language)' localizable strings in bundle \(bundle).")
			
			/// In order to prevent loading for each key, enter a fake entry
			/// into the localization.
			_cachedLanguageDicts[bundle]![language] = ["__XU_LOCALIZATION_PLACEHOLDER__" : ""]
			
			return key
		}
		
		do {
			let object = try PropertyListSerialization.propertyList(from: data, options: PropertyListSerialization.MutabilityOptions(), format: nil)
			guard let d = object as? [String : String] else {
				XULog("Invalid localization loaded - '\(language)' \(type(of: object)) \(object).")
				
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
	public func localizedStringWithFormatValues(_ key: String, andValues values: [String : AnyObject]) -> String {
		var localizedString = self.localizedString(key)
		for (key, value) in values {
			let needle = "{\(key)}"
			if localizedString.range(of: needle) == nil {
				XULogStacktrace("Localized string \(localizedString) doesn't have a placeholder for key \(key)")
			}
			
			localizedString = localizedString.replacingOccurrences(of: needle, with: value.description)
		}
		return localizedString
	}

	/// Returns the identifier of current localization.
	@available(*, deprecated, message: "Use the variations with bundle specifications.")
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
@available(*, deprecated, message: "Use XUCurrentLocalizationIdentifierForBundle instead.")
public func XUCurrentLocalizationLanguageIdentifier() -> String {
	return XULocalizationCenter.sharedCenter.currentLocalizationLanguageIdentifier
}
