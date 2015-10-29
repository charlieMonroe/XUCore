// 
// NSColorAdditions.h
// 
// Created by Charlie Monroe
// 
// Copyright (c) 2010-13 Fuel Collective, LLC. All rights reserved.
// 


#import <Cocoa/Cocoa.h>


@interface NSColor (NSColorAdditions) 

//Must be called from -mouseDown: as it calls -dragImage:at:offset:event:pasteboard:source:slideBack: on view - view also is set as the drag source
-(void)dragWithEvent:(NSEvent*)event sourceView:(NSView*)view;

@end

