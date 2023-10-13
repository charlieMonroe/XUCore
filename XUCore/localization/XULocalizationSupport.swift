//
//  XULocalizationSupport.swift
//  XUCore
//
//  Created by Charlie Monroe on 11/25/15.
//  Copyright © 2015 Charlie Monroe Software. All rights reserved.
//

import Foundation

private extension XUPreferences.Key {
	static let language = XUPreferences.Key(rawValue: "XULanguage")
}

private extension XUPreferences {
	
	var languageIdentifier: String? {
		get {
			return self.value(for: .language)
		}
		nonmutating set {
			self.set(value: newValue, forKey: .language)
		}
	}
	
}

/// A UI element that's localizable. See localization support files for NSView,
/// NSWindow, NSMenu, UIView.
public protocol XULocalizableUIElement {
	
	/// Localizes the element using localization from a particular bundle.
	func localize(from bundle: Bundle)
	
}

/// Returns a localized string.
///
/// If there are any arguments, then it returns a formatted string, just like `String(format:)` would return,
/// but the format string gets localized first.
@inline(__always)
public func Localized(_ key: String, _ arguments: CVarArg..., in bundle: Bundle = .main, locale language: String? = nil) -> String {
	let locale = language ?? XULocalizationCenter.shared.localizationIdentifier(for: bundle)
	let localized = XULocalizationCenter.shared.localizedString(key, withLocale: locale, inBundle: bundle)
	if arguments.count == 0 {
		return localized
	}
	return String(format: localized, arguments: arguments)
}

/// Returns a localized string. Soft-deprecated. Use `Localized(_:)` instead.
@inline(__always)
@available(*, deprecated)
public func XULocalizedString(_ key: String, inBundle bundle: Bundle = .main, withLocale language: String? = nil) -> String {
	return Localized(key, in: bundle, locale: language)
}

/// Returns a formatted string, just like [NSString stringWithFormat:] would return,
/// but the format string gets localized first.
///
/// Soft-deprecated. Use `Localized(_:)` instead.
@inline(__always)
@available(*, deprecated, renamed: "Localized(_:_:in:locale:)")
public func XULocalizedFormattedString(_ format: String, _ arguments: CVarArg..., withLocale language: String? = nil, inBundle bundle: Bundle = .main) -> String {
	return String(format: Localized(format, in: bundle, locale: language), arguments: arguments)
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
///
/// As this is not being used anywhere, it is being deprecated.
@available(*, deprecated)
public func Localized(_ key: String, withFormatValues values: [String : Any]) -> String {
	return XULocalizationCenter.shared.localizedString(key, withValues: values)
}

/// This class contains all the necessary methods for localization. You should,
/// however, use the global functions instead, this class is mostly for encapsulation.
public final class XULocalizationCenter {
	
	/// Shared instance.
	public static let shared: XULocalizationCenter = XULocalizationCenter()

	/// Cached identifiers
	private var _cachedLanguageIdentifiers: [Bundle : String] = [:]
	
	/// Cached language dictionaries.
	private var _cachedLanguageDicts: [Bundle: [String : [String : String]]] = [:]
	
	/// When running the app with a debuggable dicationary, this is nonnil and contains mapping of
	/// identifier -> table.
	private var _debuggingLanguageDict: [String : [String : String]]?
	
	/// Lock for modifying `_cachedLanguageDicts`
	private let _lock: NSRecursiveLock = NSRecursiveLock(name: "com.charliemonroe.XULocalization")
	
	/// A mapping of bundle -> identifiers used when debugging localization.
	private var _registeredIdentifiers: [Bundle : [String]] = [
		.core: ["com.charliemonroe.xu.core"]
	]
	
	/// Set of localization tables the center should be using.
	private var _registeredTableNames: [Bundle : [String]] = [:]
	
	/// The language is often e.g. en-US - we need to find the language identifier
	/// that is in that particular bundle.
	private func _identifierFromComposedIdentifier(_ language: String, inBundle bundle: Bundle) -> String? {
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
	private func _languageBundleForLanguage(_ language: String, inBundle bundle: Bundle, fallbackToEnglish: Bool = true) -> Bundle? {
		if let url = bundle.url(forResource: language, withExtension: "lproj") {
			return Bundle(url: url)
		}
		
		// Fall back to en or "Base". Just check if the language is "en" so that if
		// the project doesn't contain either, we don't end up in an infinite loop.
		if language == "en" {
			if let bundle = self._languageBundleForLanguage("English", inBundle: bundle, fallbackToEnglish: fallbackToEnglish) {
				return bundle
		 } else if let bundle = self._languageBundleForLanguage("Base", inBundle: bundle, fallbackToEnglish: fallbackToEnglish) {
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
	public func localizationIdentifier(for bundle: Bundle) -> String {
		if let identifier = _lock.perform(locked: { _cachedLanguageIdentifiers[bundle] }) {
			return identifier
		}
		
		if let identifier = XUPreferences.shared.languageIdentifier {
			_lock.perform {
				self._cachedLanguageIdentifiers[bundle] = identifier
			}
			return identifier
		}
		
		let languageArrays = [Locale.preferredLanguages, UserDefaults.standard.array(forKey: "AppleLanguages") as? [String]].compacted()
		
		for languages in languageArrays {
			for language in languages {
				if let identifier = self._identifierFromComposedIdentifier(language, inBundle: bundle) {
					_lock.perform {
						self._cachedLanguageIdentifiers[bundle] = identifier
					}
					return identifier
				}
			}
		}
		
		if let identifier = self._identifierFromComposedIdentifier(Locale.current.identifier, inBundle: bundle) {
			_lock.perform {
				self._cachedLanguageIdentifiers[bundle] = identifier
			}
			return identifier
		}
		
		/// This is pure desperation - the bundle is unlikely to have localization
		/// for any requested languages.
		let identifier = Locale.current.identifier
		_lock.perform {
			self._cachedLanguageIdentifiers[bundle] = identifier
		}

		return identifier
	}
	
	/// Set a localization identifier.
	public func setCurrentLocalizationIdentifier(_ identifier: String) {
		let defs = UserDefaults.standard
		var languages = defs.array(forKey: "AppleLanguages") as? [String] ?? [ ]
		if let index = languages.firstIndex(of: identifier) {
			languages.remove(at: index)
		}
		languages.insert(identifier, at: 0)
		
		defs.set(languages, forKey: "AppleLanguages")
		
		XUPreferences.shared.perform { (prefs) in
			prefs.languageIdentifier = identifier
		}
		
		_lock.perform {
			self._cachedLanguageIdentifiers = [:]
		}
	}
	
	private func _loadLocalizations(for language: String, in bundle: Bundle) {
		guard let languageBundle = self._languageBundleForLanguage(language, inBundle: bundle) else {
			/// In order to prevent loading for each key, enter a fake entry
			/// into the localization.
			_cachedLanguageDicts[bundle]![language] = ["__XU_LOCALIZATION_PLACEHOLDER__" : ""]
			return // No such localization
		}
		
		for table in _registeredTableNames[bundle, default: ["Localizable"]] {
			guard
				let url = languageBundle.url(forResource: table, withExtension: "strings", subdirectory: nil, localization: language),
				let data = try? Data(contentsOf: url)
			else {
				XULog("No '\(language)' localizable strings for table \(table) in bundle \(bundle).")
				continue
			}
			
			do {
				let object = try PropertyListSerialization.propertyList(from: data, options: PropertyListSerialization.MutabilityOptions(), format: nil)
				guard let d = object as? [String : String] else {
					XULog("Invalid localization loaded - '\(language)' \(type(of: object)) \(object).")
					continue
				}
				
				_cachedLanguageDicts[bundle]![language, default: [:]] += d
			} catch let err as NSError {
				XULog("Failed to read '\(language)' localizable strings \(err).")
				continue
			}
		}
		
		if _cachedLanguageDicts[bundle]![language].isNilOrEmpty {
			/// In order to prevent loading for each key, enter a fake entry
			/// into the localization.
			_cachedLanguageDicts[bundle]![language] = ["__XU_LOCALIZATION_PLACEHOLDER__" : ""]
		}
	}
	
	/// Returns a localized string.
	public func localizedString(_ key: String, withLocale _language: String? = nil, inBundle bundle: Bundle = Bundle.main) -> String {
		let language = _language ?? self.localizationIdentifier(for: bundle)
		
		if key.isEmpty {
			return key
		}
		
		/// Always prefer debug value when running localization debugging.
		if let bundleIdentifiers = _registeredIdentifiers[bundle], let value = bundleIdentifiers.firstNonNilValue(using: { _debuggingLanguageDict?[$0]?[key] }) {
			return value
		}

		
		_lock.lock()
		defer {
			_lock.unlock()
		}
		
		/// Perhaps, it's already loaded.
		if let value = _cachedLanguageDicts[bundle]?[language]?[key] {
			return value
		}
		
		/// Handle a common scenario where the keys only differ with '...'.
		for suffix in ["...", "…", ":"] where key.hasSuffix(suffix) {
			let updatedKey = key.deleting(suffix: suffix)
			if let value = _cachedLanguageDicts[bundle]?[language]?[updatedKey] {
				// Update the dictionary.
				let updatedValue = value + suffix
				_cachedLanguageDicts[bundle]?[language]?[key] = updatedValue
				return updatedValue
			}
		}
		
		/// Try it the other way.
		if
			let updatedKeyValue = ["...", "…", ":"].firstNonNilValue(using: { (suffix) -> (key: String, value: String)? in
				if let value = _cachedLanguageDicts[bundle]?[language]?[key + suffix] {
					return (key: key + suffix, value: value)
				} else {
					return nil
				}
			})
		{
			// Update the dictionary.
			_cachedLanguageDicts[bundle]?[language]?[updatedKeyValue.key] = updatedKeyValue.value
			return updatedKeyValue.value
		}
		
		/// Now, we know that the string isn't in the localization. There are two
		/// options. Either the localization doesn't contain this phrase, or it
		/// hasn't been loaded yet.
		if let languageDict = _cachedLanguageDicts[bundle]?[language], !languageDict.isEmpty {
			/// The language has already been loaded -> no point in reloading it.
			return key
		}
		
		if _cachedLanguageDicts[bundle] == nil {
			_cachedLanguageDicts[bundle] = [:]
		}
		
		self._loadLocalizations(for: language, in: bundle)
		return _cachedLanguageDicts[bundle]![language]?[key] ?? key
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
	public func localizedString(_ key: String, withValues values: [String : Any]) -> String {
		var localizedString = self.localizedString(key)
		for (key, value) in values {
			let needle = "{\(key)}"
			if localizedString.range(of: needle) == nil {
				XULogStacktrace("Localized string \(localizedString) doesn't have a placeholder for key \(key)")
			}
			
			localizedString = localizedString.replacingOccurrences(of: needle, with: String(describing: value))
		}
		return localizedString
	}

	/// Registers a table name containing localizations. This should be called before calling
	/// any of the localization methods.
	public func registerTableName(_ name: String, for bundle: Bundle) {
		var names = _registeredTableNames[bundle] ?? ["Localizable"]
		guard !names.contains(name) else {
			return
		}
		
		names.append(name)
		_registeredTableNames[bundle] = names
	}
	
	/// This is for debugging purposes, when debugging the app with a custom `.cmloc` file. This
	/// registers a bundle with a particular identifier so that the localization center knows what component
	/// to look into.
	public func registerBundle(_ bundle: Bundle, with identifier: String) {
		_registeredIdentifiers[bundle, default: []].append(identifier)
	}
	
	
	private enum LocalizationDebuggingInitializationError: Error {
		case invalidDictionary
		case invalidPhrase([String : String])
	}
	
	
	private init() {
		XULog("Intializing localization center.")
		
		guard
			let index = CommandLine.arguments.firstIndex(of: "--debug-localization"),
			CommandLine.arguments.count >= index
		else {
			XULog("Not debugging localization - \(CommandLine.arguments).")
			return
		}
		
		let url = URL(fileURLWithPath: CommandLine.arguments[index + 1])
		XULog("Will debug localization from - \(url).")
		
		do {
			let components = try NSArray(contentsOf: url, error: ())
			var debuggingLanguageDict: [String : [String : String]] = [:]
			for component in components {
				guard
					let componentDict = component as? [String : Any],
					let identifier = componentDict["identifier"] as? String,
					let phrases = componentDict["phrases"] as? [[String : String]]
				else {
					throw LocalizationDebuggingInitializationError.invalidDictionary
				}
				
				for phrase in phrases {
					guard let original = phrase["original"], let translation = phrase["translation"] else {
						throw LocalizationDebuggingInitializationError.invalidPhrase(phrase)
					}
					
					debuggingLanguageDict[identifier, default: [:]][original] = translation
				}
			}
			
			_debuggingLanguageDict = debuggingLanguageDict
		} catch {
			XUFatalError("Failed to launch with localization debugging due to an error: \(error)")
		}
	}
	
}

