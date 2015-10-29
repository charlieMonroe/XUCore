// 
// NSWindow-NoodleEffects.h
// 
// Created by Charlie Monroe
// 
// Copyright (c) 2010-13 Fuel Collective, LLC. All rights reserved.
// 


#import <Cocoa/Cocoa.h>


@interface NSWindow (NoodleEffects)

- (void)zoomOnFromRect:(NSRect)startRect;
- (void)zoomOffToRect:(NSRect)endRect;

-(void)pop;
-(void)popAway;
@end

