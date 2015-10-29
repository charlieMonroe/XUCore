// 
// NSTextFieldAdditions.m
// 
// Created by Charlie Monroe
// 
// Copyright (c) 2010-13 Fuel Collective, LLC. All rights reserved.
// 


#import "NSTextFieldAdditions.h"
#import "NSStringGeometrics.h"

static CGFloat kBorderWidth = 10.0;

@implementation NSTextField (NSTextFieldAdditions)


-(NSRect)sizeToFitKeepingWidth:(BOOL)resizeDownwards{
	NSRect textFrame = NSInsetRect([self bounds], kBorderWidth, kBorderWidth);
	
	CGFloat textHeight = [[self stringValue] heightForWidth:NSWidth(textFrame) font:[self font]];
	
	CGFloat deltaHeight = NSHeight(textFrame) - textHeight;
	NSRect myFrame = [self frame];
	myFrame.size.height -= deltaHeight;
	if (resizeDownwards){
		myFrame.origin.y += deltaHeight;
	}
	[self setFrame:myFrame];
	
	return myFrame;
}

@end

