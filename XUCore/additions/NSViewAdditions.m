// 
// NSViewAdditions.m
// 
// Created by Charlie Monroe
// 
// Copyright (c) 2010-13 Fuel Collective, LLC. All rights reserved.
// 


#import "NSViewAdditions.h"


@implementation NSView (NSViewAdditions)
-(NSRect)screenCoordinatesOfFrame:(NSRect)frame{
	NSRect rect = [self convertRect:frame toView:nil];
	NSRect windowFrame = [[self window] frame];
	rect.origin.x += windowFrame.origin.x;
	rect.origin.y += windowFrame.origin.y;
	return rect;
}
-(NSPoint)screenCoordinatesOfPoint:(NSPoint)point{
	point = [self convertPoint:point toView:nil];
	NSRect windowFrame = [[self window] frame];
	point.x += windowFrame.origin.x;
	point.y += windowFrame.origin.y;
	return point;
}
-(NSRect)screenCoordinatesOfSelf{
	return [self screenCoordinatesOfFrame:[self bounds]];
}
-(void)setDeepEnabled:(BOOL)flag{
	for (NSView *view in [self subviews]){
		if ([view respondsToSelector:@selector(setEnabled:)]){
			[(NSControl*)view setEnabled:flag];
		}else{
			[view setDeepEnabled:flag];
		}
	}
}
@end

