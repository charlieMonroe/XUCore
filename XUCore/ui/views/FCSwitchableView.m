// 
// FCSwitchableView.m
// 
// Created by Charlie Monroe
// 
// Copyright (c) 2010-13 Fuel Collective, LLC. All rights reserved.
// 


#import "FCSwitchableView.h"


@implementation FCSwitchableView
//Only for debug purposes
/*
 -(void)drawRect:(NSRect)dirtyRect{
	[[NSColor blueColor] set];
	NSRectFill(dirtyRect);
}
 
 */
-(void)dealloc{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}
-(NSView*)currentView{
	return _currentView;
}
-(void)setCurrentView:(NSView *)view{
	if (_currentView == nil){
		[view setFrame:[self bounds]];
		[self addSubview:view];
	}
	_currentView = view;
}
-(instancetype)initWithFrame:(NSRect)frame{
	if ((self = [super initWithFrame:frame])!=nil){
		[self setPostsFrameChangedNotifications:YES];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_frameChanged:) name:NSViewFrameDidChangeNotification object:self];
	}
	return self;
}

-(void)setANewView:(NSView*)view inDirection:(FCDirection)direction adjustWindow:(BOOL)flag{
	_isAnimating = YES;
	
	//Make sure the view isn't hidden
	if ([_otherView isHidden]){
		[_otherView setHidden:NO];
	}
	
	if ([self currentView] == nil){
		//There is currently no view, so just add the new one, no animation
		[self addSubview:view];
		[view setFrame:[self bounds]];
		_currentView = view;
		return;
	}
	
	if ([self currentView] == view){
		//It's the same view, do nothing
		return;
	}
	
	[NSAnimationContext beginGrouping];
	// [[NSAnimationContext currentContext] setDuration:3.0];
	
	NSSize newViewSize = [view bounds].size;
	NSSize oldViewSize = [_currentView bounds].size;
	
	if (flag){
		//Adjust the window - this is based on deltas
		NSRect newFrame = [[self window] frame];
		
		float delta = (newViewSize.width - oldViewSize.width);
		newFrame.size.width += delta;
		newFrame.origin.x -= delta/2.0; //Keeping it centered
		
		//Height delta
		delta = (newViewSize.height - oldViewSize.height);
		newFrame.size.height += delta;
		newFrame.origin.y -= delta; //Keeping the top aligned
		
		[[[self window] animator] setFrame:newFrame display:YES];
	}
	
	
	NSRect r = [self bounds];
	
	NSSize targetSize = flag ? newViewSize : r.size;
	
	NSRect newViewRect; //The rect in which the new view should be placed (it's offscreen)
	NSRect toBeMoved; //The rect where the current view should move out to make place for the new view
	
	if (direction==FCLeft){ //From left to right
		newViewRect = NSMakeRect(oldViewSize.width, oldViewSize.height - newViewSize.height, targetSize.width, targetSize.height);
		toBeMoved = NSMakeRect(-oldViewSize.width, 0, oldViewSize.width, oldViewSize.height);
	}else if (direction==FCRight){ //From right to left
		newViewRect = NSMakeRect(-newViewSize.width, oldViewSize.height - newViewSize.height, newViewSize.width, newViewSize.height);
		toBeMoved = NSMakeRect(oldViewSize.width, 0, oldViewSize.width, oldViewSize.height);
	}else if (direction==FCBottom){ //From up to down
		newViewRect = NSMakeRect(0, r.size.height, r.size.width, r.size.height);
		toBeMoved = NSMakeRect(0, -r.size.height, r.size.width, r.size.height);
	}else{  //FCTop - from down to up
		newViewRect = NSMakeRect(0, -r.size.height, r.size.width, r.size.height);
		toBeMoved = NSMakeRect(0, r.size.height, r.size.width, r.size.height);
	}
	
	//Add the new view offscreen
	[view setFrame:newViewRect];
	[self addSubview:view];
	
	//Calculate the target frame of the new view
	NSRect targetNewViewFrame = r;
	if (flag){
		targetNewViewFrame.size = newViewSize;
	}
	[[view animator] setFrame:targetNewViewFrame];
	
	[[[self currentView] animator] setFrame:toBeMoved];
	
	[NSAnimationContext endGrouping];
	
	_otherView = _currentView;
	_currentView = view;
	
	[NSTimer scheduledTimerWithTimeInterval:[[NSAnimationContext currentContext] duration] target:self selector:@selector(unsetAnimation:) userInfo:nil repeats:NO];
}
-(void)setANewView:(NSView*)view inDirection:(FCDirection)direction{
	[self setANewView:view inDirection:direction adjustWindow:NO];
	
}

-(void)unsetAnimation:(id)sender{
	_isAnimating = NO;
	
	//Remove the previous cached view
	[_otherView removeFromSuperview];
	_otherView = nil;
	
	[[self currentView] setFrame:[self bounds]];
}

-(void)_frameChanged:(id)sender{
	//! NSEqualRects([self bounds], [[self superview] bounds])
	if (_isAnimating){
		return;
	}
	[[self currentView] setFrame:[self bounds]];
	if (![_otherView isHidden]){
		[_otherView setHidden:YES];
	}
}

@end

