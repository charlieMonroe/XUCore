// 
// NSViewLocalizationSupport.h
// 
// Created by Charlie Monroe
// 
// Copyright (c) 2010-13 Fuel Collective, LLC. All rights reserved.
// 

#import <Foundation/Foundation.h>
#if TARGET_OS_IPHONE
	#import <UIKit/UIKit.h>
	#define NSView UIView
#else
	#import <Cocoa/Cocoa.h>
#endif


@interface NSView (NSViewLocalizationSupport)
-(void)localizeView;
@end

