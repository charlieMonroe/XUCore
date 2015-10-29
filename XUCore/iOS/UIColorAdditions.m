// 
// UIColorAdditions.m
// 
// Created by Charlie Monroe
// 
// Copyright (c) 2010-13 Fuel Collective, LLC. All rights reserved.
// 


#import "UIColorAdditions.h"
#import "FCiPhoneDrawing.h"

@implementation UIColor (UIColorAdditions)
-(UIImage *)colorSwatchOfSize:(CGSize)aSize{
#define sideSize 26.0
	
	float radius = 6.0;
	
	UIImage *maskedImage = nil;
	CGRect dstRect = CGRectMake(0.0, 0.0, sideSize, sideSize);
	
	
	radius = MIN(radius, sideSize/2.0);
	
	UIGraphicsBeginImageContext(dstRect.size);
	CGContextRef ctx = UIGraphicsGetCurrentContext();
	
	[self set];
	
	CGContextAddRoundedRect(ctx, dstRect, radius);
	CGContextFillPath(ctx);
	
	[[UIColor whiteColor] set];

	maskedImage = UIGraphicsGetImageFromCurrentImageContext();
	
	UIGraphicsEndImageContext();
	
	return maskedImage;

}
@end

