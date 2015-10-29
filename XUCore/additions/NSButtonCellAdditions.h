// 
// NSButtonCellAdditions.h
// 
// Created by Charlie Monroe
// 
// Copyright (c) 2010-13 Fuel Collective, LLC. All rights reserved.
// 


#import <Cocoa/Cocoa.h>


@interface NSButtonCell (MouseLocationAdditions)

-(BOOL)mouseInside;
-(void)setMouseInside:(BOOL)isInside;

@end
