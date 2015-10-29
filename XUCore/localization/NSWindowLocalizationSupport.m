// 
// NSWindowLocalizationSupport.m
// 
// Created by Charlie Monroe
// 
// Copyright (c) 2010-13 Fuel Collective, LLC. All rights reserved.
// 


#import "NSWindowLocalizationSupport.h"

#ifndef FCLocalizedString
	#import "FCLocalizationSupport.h"
#endif

@implementation NSWindow (NSWindowLocalizationSupport)
-(void)localizeWindow{
	[self setTitle:FCLocalizedString([self title])];
	[[self contentView] localizeView];
	
	NSToolbar *toolbar = [self toolbar];
	for (NSToolbarItem *item in [toolbar items]){
		[item setLabel:FCLocalizedString([item label])];
	}
}
@end

