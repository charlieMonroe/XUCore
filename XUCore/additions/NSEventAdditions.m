// 
// NSEventAdditions.m
// 
// Created by Charlie Monroe
// 
// Copyright (c) 2010-13 Fuel Collective, LLC. All rights reserved.
// 


#import "NSEventAdditions.h"
#import <Carbon/Carbon.h>


@implementation NSEvent (NSEventAdditions)
+(BOOL)commandKeyDown{
	UInt32 currentKeyModifiers = GetCurrentKeyModifiers();
	UInt32 result = (currentKeyModifiers & cmdKey);
	return result != 0;
}
+(BOOL)controlKeyDown{
	UInt32 currentKeyModifiers = GetCurrentKeyModifiers();
	UInt32 result = (currentKeyModifiers & controlKey);
	return result != 0;
}
+(BOOL)optionKeyDown{
	UInt32 currentKeyModifiers = GetCurrentKeyModifiers();
	UInt32 result = (currentKeyModifiers & optionKey);
	return result != 0;
}
@end

