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


@interface _XU_NSColorDraggingSource : NSObject <NSDraggingSource>

@end

@implementation _XU_NSColorDraggingSource

-(NSDragOperation)draggingSession:(NSDraggingSession *)session sourceOperationMaskForDraggingContext:(NSDraggingContext)context {
	return NSDragOperationCopy;
}

@end


static _XU_NSColorDraggingSource *_source;


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
	
	NSPoint p = [view convertPoint:[event locationInWindow] fromView:nil];
	p.x -= 6.0;
	p.y -= 6.0;
	
	NSDraggingItem *item = [[NSDraggingItem alloc] initWithPasteboardWriter:self];
	[item setImageComponentsProvider:^NSArray<NSDraggingImageComponent *> * _Nonnull{
		NSDraggingImageComponent *component = [[NSDraggingImageComponent alloc] initWithKey:@"Color"];
		[component setContents:image];
		return @[ component ];
	}];
	[item setDraggingFrame:CGRectMake(p.x, p.y, 12.0, 12.0)];
	
	
	if (_source == nil) {
		_source = [[_XU_NSColorDraggingSource alloc] init];
	}
	[view beginDraggingSessionWithItems:@[ item ] event:event source:_source];
	
}

@end

