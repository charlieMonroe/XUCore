// 
// NSTabViewAdditions.m
// 
// Created by Charlie Monroe
// 
// Copyright (c) 2010-13 Fuel Collective, LLC. All rights reserved.
// 


#import "NSTabViewAdditions.h"
#import "NSViewAdditions.h"

@implementation NSTabView (NSTabViewAdditions)
-(void)setDeepEnabled:(BOOL)flag{
	for (NSTabViewItem *item in [self tabViewItems]){
		[[item view] setDeepEnabled:flag];
	}
}
@end

