
//
// NSShadowAdditions.m
// 
// Created by Charlie Monroe
// 
// Copyright (c) 2010-13 Fuel Collective, LLC. All rights reserved.
// 


#import "NSShadowAdditions.h"

@implementation NSShadow (NSShadowAdditions)
+(NSShadow*)shadow{
	return [self shadowWithColor:[NSColor clearColor] offset:NSZeroSize blurRadius:0.0];
}
+(NSShadow*)shadowWithColor:(NSColor*)color offset:(NSSize)offset blurRadius:(CGFloat)radius{
	NSShadow *shadow = [[NSShadow alloc] init];
	[shadow setShadowColor:color];
	[shadow setShadowOffset:offset];
	[shadow setShadowBlurRadius:radius];
	return shadow;
}

@end

