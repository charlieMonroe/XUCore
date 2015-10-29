// 
// NSEventAdditions.h
// 
// Created by Charlie Monroe
// 
// Copyright (c) 2010-13 Fuel Collective, LLC. All rights reserved.
// 


#import <Cocoa/Cocoa.h>

enum FCKeyCodes {
	FCReturn = 36,
	FCEnter = 76,
	FCEscape = 53,
	FCBackspace = 51,
	FCDelete = 117,
	FCSpacebar = 49,
	FCKeyLeft = 123,
	FCKeyRight = 124,
	FCKeyDown = 125,
	FCKeyUp = 126
};


@interface NSEvent (NSEventAdditions) 
+(BOOL)commandKeyDown;
+(BOOL)controlKeyDown;
+(BOOL)optionKeyDown;
@end

