// 
// FCMenuButton.m
// 
// Created by Charlie Monroe
// 
// Copyright (c) 2010-13 Fuel Collective, LLC. All rights reserved.
// 


#import "FCMenuButton.h"
#import "FCLocalizationSupport.h"


@implementation FCMenuButton
-(void)_displayMenu{
	NSMenu *menu = [self menu];
	
	[menu popUpMenuPositioningItem:nil atLocation:NSMakePoint(0.0, NSHeight([self bounds])) inView:self];
}
-(void)awakeFromNib{
	[self setTarget:self];
	[self setAction:@selector(_displayMenu)];
	
	[[self menu] localizeMenu];
}
-(void)rightMouseDown:(NSEvent *)theEvent{
	[self _displayMenu];
}

@end

