// 
// NSShadowAdditions.h
// 
// Created by Charlie Monroe
// 
// Copyright (c) 2010-13 Fuel Collective, LLC. All rights reserved.
// 


#import <Cocoa/Cocoa.h>


@interface NSShadow (NSShadowAdditions)

+(nonnull instancetype)shadow;
+(nonnull instancetype)shadowWithColor:(nonnull NSColor *)color offset:(CGSize)offset blurRadius:(CGFloat)radius;

@end

