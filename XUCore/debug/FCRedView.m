// 
// FCRedView.m
// 
// Created by Charlie Monroe
// 
// Copyright (c) 2010-13 Fuel Collective, LLC. All rights reserved.
// 


#import "FCRedView.h"


@implementation FCRedView

- (void)drawRect:(NSRect)dirtyRect {
	[[NSColor redColor] set];
	NSRectFill(dirtyRect);
}
-(BOOL)isFlipped{
	return YES;
}

@end

