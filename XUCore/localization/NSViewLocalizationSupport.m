// 
// NSViewLocalizationSupport.m
// 
// Created by Charlie Monroe
// 
// Copyright (c) 2010-13 Fuel Collective, LLC. All rights reserved.
// 


#import "NSViewLocalizationSupport.h"

#ifndef FCLocalizedString
	#import "FCLocalizationSupport.h"
#endif

#if TARGET_OS_IPHONE

@implementation UIButton (NSViewLocalizationSupport)
-(void)localizeView{
	[self setTitle:FCLocalizedString([self titleForState:UIControlStateNormal]) forState:UIControlStateNormal];
}
@end

@implementation UILabel (NSViewLocalizationSupport)
-(void)localizeView{
	[self setText:FCLocalizedString([self text])];
}
@end

@implementation UITextField (NSViewLocalizationSupport)
-(void)localizeView{
	[self setPlaceholder:FCLocalizedString([self placeholder])];
}
@end

#else
@implementation NSPopUpButton (NSViewLocalizationSupport)
-(void)localizeView{
	[[self menu] localizeMenu];
	[self setTitle:FCLocalizedString([self title])];
}
@end

@implementation NSButton (NSViewLocalizationSupport)
-(void)localizeView{
	[[self menu] localizeMenu];
	if ([self imagePosition] != NSImageOnly){
		[self setTitle:FCLocalizedString([self title])];
	}
}
@end

@implementation NSTextField (NSViewLocalizationSupport)
-(void)localizeView{
	[self setStringValue:FCLocalizedString([self stringValue])];
}
@end

@implementation NSTabView (NSViewLocalizationSupport)

-(void)localizeView{
	for (NSTabViewItem *item in [self tabViewItems]){
		[item setLabel:FCLocalizedString([item label])];
		[[item view] localizeView];
	}
}

@end

@implementation NSTableView (NSViewLocalizationSupport)
-(void)localizeView{
	for (NSTableColumn *column in [self tableColumns]){
		[[column headerCell] setTitle:FCLocalizedString([[column headerCell] title])];
	}
}
@end

@implementation NSSegmentedControl (NSViewLocalizationSupport)
-(void)localizeView{
	for (NSInteger i = 0; i < [self segmentCount]; ++i){
		[self setLabel:FCLocalizedString([self labelForSegment:i]) forSegment:i];
	}
}
@end
#endif

@implementation NSView (NSViewLocalizationSupport)
-(void)localizeView{
	for (NSView *view in [self subviews]){
		[view localizeView];
	}
}
@end

