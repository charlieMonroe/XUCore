// 
// NSViewAdditions.h
// 
// Created by Charlie Monroe
// 
// Copyright (c) 2010-13 Fuel Collective, LLC. All rights reserved.
// 


#import <Cocoa/Cocoa.h>


@interface NSView (NSViewAdditions)

-(void)setDeepEnabled:(BOOL)flag;

-(NSRect)screenCoordinatesOfSelf;
-(NSRect)screenCoordinatesOfFrame:(NSRect)frame;
-(NSPoint)screenCoordinatesOfPoint:(NSPoint)point;

@end

