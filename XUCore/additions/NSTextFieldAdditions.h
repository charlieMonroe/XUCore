// 
// NSTextFieldAdditions.h
// 
// Created by Charlie Monroe
// 
// Copyright (c) 2010-13 Fuel Collective, LLC. All rights reserved.
// 


#import <Cocoa/Cocoa.h>


@interface NSTextField (NSTextFieldAdditions)

/** If downwards flag is NO, it only updates the frame's height, keeping the origin. */
-(NSRect)sizeToFitKeepingWidth:(BOOL)resizeDownwards;

@end

