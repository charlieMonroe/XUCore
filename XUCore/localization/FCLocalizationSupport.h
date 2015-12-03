// 
// FCLocalizationSupport.h
// 
// Created by Charlie Monroe
// 
// Copyright (c) 2010-14 Charlie Monroe Software. All rights reserved.
// 

/*
 * Allows easy localization. Just use FCLocalizedString(@"Str") or FCLocalizedFormattedString(@"Str %@", obj).
 */

#import <Foundation/Foundation.h>

/** We cannot migrare this file to Swift yet, since the compiler doesn't include
 * functions in XUCore-Swift.h...
 */

extern NS_SWIFT_UNAVAILABLE("Use XULocalizedString instead") NSString * __nonnull FCLocalizedString(NSString * __nonnull key);
#define XULocalizedString(key) FCLocalizedString(key)
#define XULocalizedStringWithLocale(key, locale) [[XULocalizationCenter sharedCenter] localizedString:key withLocale:locale]

/**
 * A new format function which takes `values` and replaces placeholders within `key`
 * with values from `values`.
 *
 * Example:
 *
 *  `key` = @"I have {number} apples."
 *  `values` = @{ @"number" : @"2" }
 *
 *  results in @"I have 2 apples."
 *
 * @note `values` can have values other than NSString - -description is called
 *            on the values.
 *
 */
extern NSString * __nonnull FCLocalizedStringWithFormatValues(NSString * __nonnull key, NSDictionary<NSString *, id> * __nonnull values);


#define FCLocalizedFormattedString(key, ...) [NSString stringWithFormat:FCLocalizedString(key), __VA_ARGS__]
#define XULocalizedFormattedString(key, ...) [NSString stringWithFormat:FCLocalizedString(key), __VA_ARGS__]
#define XULocalizedFormattedStringWithLocale(key, lang, ...) [NSString stringWithFormat:XULocalizedStringWithLocale(key, lang), __VA_ARGS__]
