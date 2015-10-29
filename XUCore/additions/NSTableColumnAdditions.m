// 
// NSTableColumnAdditions.m
// 
// Created by Charlie Monroe
// 
// Copyright (c) 2010-13 Fuel Collective, LLC. All rights reserved.
// 


#import "NSTableColumnAdditions.h"


@implementation NSTableColumn (FCAdditions)

-(NSString*)title{
	return [[self headerCell] stringValue];
}

@end


