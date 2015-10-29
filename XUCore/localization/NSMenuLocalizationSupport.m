// 
// NSMenuLocalizationSupport.m
// 
// Created by Charlie Monroe
// 
// Copyright (c) 2010-13 Fuel Collective, LLC. All rights reserved.
// 


#import "NSMenuLocalizationSupport.h"

#ifndef FCLocalizedString
	#import "FCLocalizationSupport.h"
#endif

@implementation NSMenu (NSMenuLocalizationSupport)
-(void)localizeMenu{
	[self setTitle:FCLocalizedString([self title])];
	for (NSMenuItem *item in [self itemArray]){
		if ([item attributedTitle] != nil){
			NSAttributedString *attributedTitle = [item attributedTitle];
			NSString *localizedTitle = FCLocalizedString([attributedTitle string]);
			NSAttributedString *localizedAttributedTitle = [[NSAttributedString alloc] initWithString:localizedTitle attributes:[attributedTitle attributesAtIndex:0 effectiveRange:NULL]];
			[item setAttributedTitle:localizedAttributedTitle];
		}else{
			[item setTitle:FCLocalizedString([item title])];
		}
		if ([item hasSubmenu]){
			[[item submenu] localizeMenu];
		}
	}
}
@end

