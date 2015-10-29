// 
// FCSwitchableView.h
// 
// Created by Charlie Monroe
// 
// Copyright (c) 2010-13 Fuel Collective, LLC. All rights reserved.
// 


#import <Cocoa/Cocoa.h>
#import "NSBezierPathAdditions.h" //Used for FCDirection


@interface FCSwitchableView : NSView {
	__weak NSView *_currentView;
	__weak NSView *_otherView;
	BOOL _isAnimating;
}

-(void)setANewView:(nonnull NSView *)view inDirection:(FCDirection)direction; //The direction specifies where to slide the view. E.g. FCTop means from bottom to top, FCLeft means from right to left
-(void)setANewView:(nonnull NSView *)view inDirection:(FCDirection)direction adjustWindow:(BOOL)flag;

@property (nonatomic, nullable, strong) NSView *currentView; /* Force set with no animation. */

@end

