// 
// NSWindow-NoodleEffects.m
// 
// Created by Charlie Monroe
// 
// Copyright (c) 2010-13 Fuel Collective, LLC. All rights reserved.
// 


#import "NSWindow-NoodleEffects.h"
#import <Carbon/Carbon.h>

#define ZOOM_ANIMATION_TIME_MULTIPLIER			0.4
#define SLOW_ZOOM_ANIMATION_TIME_MULTIPLIER		5

@interface NoodleZoomWindow : NSPanel

@end

@implementation NoodleZoomWindow

- (NSTimeInterval)animationResizeTime:(NSRect)newWindowFrame
{
	float			multiplier;
	
	multiplier = ZOOM_ANIMATION_TIME_MULTIPLIER;


	/* if (GetCurrentEventKeyModifiers() & shiftKey)
	{

		multiplier = SLOW_ZOOM_ANIMATION_TIME_MULTIPLIER;
	}
	 */
	
	return [super animationResizeTime:newWindowFrame] * multiplier;
}

@end

@implementation NSWindow (NoodleEffects)

static NSPanel *__zoomWindow;

- (NSPanel *)_createZoomWindowWithRect:(NSRect)rect
{
	NSPanel *zoomWindow;
	NSImageView     *imageView;
	NSImage         *image;
	NSRect          frame;
	BOOL            isOneShot;
	
	frame = [self frame];

	isOneShot = [self isOneShot];
	if (isOneShot)
	{
		[self setOneShot:NO];
	}
	
	if ([self windowNumber] <= 0)
	{
		// Force window device. Kinda crufty but I don't see a visible flash
		// when doing this. May be a timing thing wrt the vertical refresh.
		[self orderBack:self];
		[self orderOut:self];
	}
	
	/* [self orderBack:self];
		[self orderOut:self]; */
	
		
	image = [[NSImage alloc] initWithSize:frame.size];
	
	NSView *view = [[self contentView] superview];
	NSBitmapImageRep *imageRep = [view bitmapImageRepForCachingDisplayInRect:[view bounds]];
	[view cacheDisplayInRect:[view bounds] toBitmapImageRep:imageRep];
	[image addRepresentation:imageRep];
	
	zoomWindow = [[NoodleZoomWindow alloc] initWithContentRect:rect styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:YES];
	[zoomWindow setBackgroundColor:[NSColor colorWithDeviceWhite:0.0 alpha:0.0]];
	[zoomWindow setHasShadow:[self hasShadow]];
	[zoomWindow setLevel:NSModalPanelWindowLevel];
	[zoomWindow setOpaque:NO];
	
	imageView = [[NSImageView alloc] initWithFrame:[zoomWindow contentRectForFrameRect:frame]];
	[imageView setImage:image];
	[imageView setImageFrameStyle:NSImageFrameNone];
	[imageView setImageScaling:NSImageScaleAxesIndependently];
	[imageView setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
	
	[zoomWindow setContentView:imageView];
	
	// Reset one shot flag
	[self setOneShot:isOneShot];
	
	__zoomWindow = zoomWindow;
	
	return zoomWindow;
}

- (void)zoomOnFromRect:(NSRect)startRect
{
	NSRect              frame;
	NSWindow            *zoomWindow;

	if ([self isVisible]){
		return;
	}
		
	frame = [self frame];
	
	[self setFrame:frame display:YES];
	
	zoomWindow = [self _createZoomWindowWithRect:startRect];
	[zoomWindow orderFront:self];
	[zoomWindow setFrame:frame display:YES animate:YES];
	
	[self orderFront:nil];
	[zoomWindow close];
	__zoomWindow = nil;
}

-(void)popAway{
	
	NSRect frame = [self frame];
	frame.origin.x += (frame.size.width/2)-10.0;
	frame.origin.y += (frame.size.height/2)-10.0;
	frame.size.width = 20.0;
	frame.size.height = 20.0;
	
	[self zoomOffToRect:frame];
}

-(void)pop{
	[self display];
	
	NSRect frame;
	NSWindow *zoomWindow;
	
	frame = [self frame];
	
	if ([self isVisible]){
		return;
	}
	
	NSRect originalFrame = frame;
	
	NSRect enlargedFrame = originalFrame;
	enlargedFrame.origin.x -= 12.5;
	enlargedFrame.origin.y -= 12.5;
	enlargedFrame.size.width += 25.0;
	enlargedFrame.size.height += 25.0;
	
	NSRect fromRect = originalFrame;
	fromRect.origin.x += originalFrame.size.width/2;
	fromRect.origin.y += originalFrame.size.height/2;
	fromRect.size.width = 1.0;
	fromRect.size.height = 1.0;
	
	zoomWindow = [self _createZoomWindowWithRect:fromRect];
	[zoomWindow orderFront:self];
	[zoomWindow setFrame:enlargedFrame display:YES animate:YES];
	[zoomWindow setFrame:originalFrame display:YES animate:YES];
	
	
	[self makeKeyAndOrderFront:self];	
	[zoomWindow close];
}

- (void)zoomOffToRect:(NSRect)endRect
{
	NSRect              frame;
	NSWindow            *zoomWindow;
	
	frame = [self frame];
	
	if (![self isVisible])
	{
		return;
	}
	
	zoomWindow = [self _createZoomWindowWithRect:frame];
	[zoomWindow orderFront:self];
//	[zoomWindow setUpWindowShadow];
	[self orderOut:self];
	
	
	[zoomWindow setFrame:endRect display:YES animate:YES];
	
	[zoomWindow close];
	
	__zoomWindow = nil;
}

@end

