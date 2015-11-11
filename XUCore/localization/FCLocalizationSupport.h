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

#ifndef LOCALIZATION_TESTING
	#define LOCALIZATION_TESTING 0
#endif

#if LOCALIZATION_TESTING
	static inline NSString *FCLocalizedString(NSString *key){
		if ([key length] == 0){
			return key;
		}
		
		NSString *result = NSLocalizedStringFromTable(key, @"Localizable", @"");
		if ([result isEqualToString:key]){
			NSLog(@"***NON-LOCALIZED KEY: \"%@\" = \"%@\";", key, key);
		}
		return result;
	}
#else
	static inline NSString * __nonnull FCLocalizedString(NSString * __nonnull key){ return NSLocalizedStringFromTable(key, @"Localizable", @""); }
#endif

#define FCLocalizedFormattedString(key, ...) [NSString stringWithFormat:FCLocalizedString(key), __VA_ARGS__]
