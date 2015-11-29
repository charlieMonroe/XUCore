//
//  FCLocalizationSupport.m
//  XUCore
//
//  Created by Charlie Monroe on 11/29/15.
//  Copyright © 2015 Charlie Monroe Software. All rights reserved.
//

#import "FCLocalizationSupport.h"

#if TARGET_OS_IOS
	#import <XUCoreMobile/XUCoreMobile-Swift.h>
#else
	#import <XUCore/XUCore-Swift.h>
#endif

NSString * __nonnull FCLocalizedString(NSString * __nonnull key){
	NSString *locale = [[XULocalizationCenter sharedCenter] currentLocalizationLanguageIdentifier];
	return [[XULocalizationCenter sharedCenter] localizedString:key withLocale:locale];
}

NSString *FCLocalizedStringWithFormatValues(NSString *key, NSDictionary *values){
	return [[XULocalizationCenter sharedCenter] localizedStringWithFormatValues:key andValues:values];
}


