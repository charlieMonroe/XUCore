// 
// NSToolbarAdditions.m
// 
// Created by Charlie Monroe
// 
// Copyright (c) 2010-13 Fuel Collective, LLC. All rights reserved.
// 


#import "NSToolbarAdditions.h"


@implementation NSToolbar (NSToolbarAdditions)

-(NSToolbarItem*)itemWithIdentifier:(NSString*)identifier{
	NSArray *items = [self items];
	for (NSToolbarItem *item in items){
		if ([[item itemIdentifier] isEqualToString:identifier]){
			return item;
		}
	}
	return nil;
}

@end

