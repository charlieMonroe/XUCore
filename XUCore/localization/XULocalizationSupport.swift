//
//  XULocalizationSupport.swift
//  XUCore
//
//  Created by Charlie Monroe on 11/25/15.
//  Copyright © 2015 Charlie Monroe Software. All rights reserved.
//

import Foundation

private let XULanguageDefaultsKey = "XULanguage"

private var _cachedLanguageDicts: [String : [String : String]] = [ : ]

/// Returns the identifier of current localization.
public func XUCurrentLocalizationLanguageIdentifier() -> String {
	if let language = NSUserDefaults.standardUserDefaults().stringForKey(XULanguageDefaultsKey) {
		return language
	}
	
	if let languages = NSUserDefaults.standardUserDefaults().arrayForKey("AppleLanguages") as? [String] {
		if let language = languages.first {
			// The language is often e.g. en-US - get just the first part
			return language.componentsSeparatedByString("-").first!
		}
	}
	
	// The language is often e.g. en-US - get just the first part
	return NSLocale.currentLocale().localeIdentifier.componentsSeparatedByString("-").first!
}

/// Sets the language identifier as the default langauge.
public func XUSetCurrentLocalizationLanguageIdentifier(identifier: String) {
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

/// Returns a localized string.
public func XULocalizedString(key: String, withLocale language: String = XUCurrentLocalizationLanguageIdentifier()) -> String {
	
	if key.isEmpty {
		return key
	}
	
	let dict: [String : String]
	if let d = _cachedLanguageDicts[language] {
		dict = d
	}else{
		guard let URL = NSBundle.mainBundle().URLForResource("Localizable", withExtension: "strings", subdirectory: nil, localization: language) else {
			return key // No such localization
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

/// Returns a formatted string, just like [NSString stringWithFormat:] would return,
/// but the format string gets localized first.
public func XULocalizedFormattedString(format: String, _ arguments: CVarArgType..., withLocale language: String = XUCurrentLocalizationLanguageIdentifier()) -> String {
	return String(format: XULocalizedString(format, withLocale: language), arguments: arguments)
}
