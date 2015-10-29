// 
// NSColorAdditions.m
// 
// Created by Charlie Monroe
// 
// Copyright (c) 2010-13 Fuel Collective, LLC. All rights reserved.
// 


#import "NSColorAdditions.h"

static CGFloat kFCColorSampleItemWidth = 24.0;
static CGFloat kFCColorSampleItemHeight = 24.0;


@implementation NSColor (NSColorAdditions)

-(NSImage*)_imagePreview{
	NSImage *image = [[NSImage alloc] initWithSize:NSMakeSize(kFCColorSampleItemWidth, kFCColorSampleItemHeight)];
	[image setBackgroundColor:[NSColor clearColor]];
	[image lockFocus];
	[self set];
	NSRect paintRect = NSMakeRect(0.0, 0.0, kFCColorSampleItemWidth, kFCColorSampleItemHeight);
	[[NSBezierPath bezierPathWithRect:paintRect] fill];
	[image unlockFocus];
	return image;
}


-(void)dragWithEvent:(NSEvent *)event sourceView:(NSView *)view{
	NSImage *image = [[NSImage alloc] initWithSize:NSMakeSize(12.0, 12.0)];
	[image lockFocus];
	
	//Draw color swatch
	[self drawSwatchInRect:NSMakeRect(0.0, 0.0, 12.0, 12.0)];
	
	//Draw border
	[[NSColor blackColor] set];
	[[NSBezierPath bezierPathWithRect:NSMakeRect(0.0, 0.0, 12.0, 12.0)] stroke];
	
	[image unlockFocus];
	
	//Write to PBoard
	NSPasteboard *dP = [NSPasteboard pasteboardWithName:NSDragPboard];
	[dP declareTypes:[NSArray arrayWithObject:NSColorPboardType] owner:self];
	
	NSImage *imagePreview = [self _imagePreview];
	NSData *TIFFData = [imagePreview TIFFRepresentation];
	NSImage *bmapImage = [[NSImage alloc] initWithData:TIFFData];
	[dP writeObjects:[NSArray arrayWithObject:bmapImage]];
	
	[self writeToPasteboard:dP];
	
	NSPoint p = [view convertPoint:[event locationInWindow] fromView:nil];
	p.x -= 6.0;
	p.y -= 6.0;
	
	[view dragImage:image at:p offset:NSMakeSize(0.0, 0.0) event:event pasteboard:dP source:view slideBack:NO];
}

@end

