//
//  FCLocalizationSupport.m
//  XUCore
//
//  Created by Charlie Monroe on 11/29/15.
//  Copyright © 2015 Charlie Monroe Software. All rights reserved.
//

#import "FCLocalizationSupport.h"

#import <XUCore/XUCore-Swift.h>

NSString * __nonnull FCLocalizedString(NSString * __nonnull key){
	NSString *locale = [[XULocalizationCenter sharedCenter] currentLocalizationLanguageIdentifier];
	return [[XULocalizationCenter sharedCenter] localizedString:key withLocale:locale inBundle:[NSBundle mainBundle]];
}

NSString *FCLocalizedStringWithFormatValues(NSString *key, NSDictionary *values){
	return [[XULocalizationCenter sharedCenter] localizedStringWithFormatValues:key andValues:values];
}


