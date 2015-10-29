// 
// UIImageAdditions.m
// 
// Created by Charlie Monroe
// 
// Copyright (c) 2010-13 Fuel Collective, LLC. All rights reserved.
// 


#import "UIImageAdditions.h"
#import "FCiPhoneDrawing.h"

@implementation UIImage (UIImageAdditions)
-(UIImage*)borderedImageWithRect:(CGRect)dstRect radius:(CGFloat)radius {
	UIImage *maskedImage = nil;
	
	radius = MIN(radius, .5 * MIN(CGRectGetWidth(dstRect), CGRectGetHeight(dstRect)));
	CGRect interiorRect = CGRectInset(dstRect, radius, radius);
	
	UIGraphicsBeginImageContext(dstRect.size);
	CGContextRef maskedContextRef = UIGraphicsGetCurrentContext();
	//CGContextSaveGState(maskedContextRef);
	
	CGMutablePathRef borderPath = CGPathCreateMutable();
	CGPathAddArc(borderPath, NULL, CGRectGetMinX(interiorRect), CGRectGetMinY(interiorRect), radius, FCDegreeToRadian(180), FCDegreeToRadian(270), NO);
	CGPathAddArc(borderPath, NULL, CGRectGetMaxX(interiorRect), CGRectGetMinY(interiorRect), radius, FCDegreeToRadian(270.0), FCDegreeToRadian(360.0), NO);
	CGPathAddArc(borderPath, NULL, CGRectGetMaxX(interiorRect), CGRectGetMaxY(interiorRect), radius, FCDegreeToRadian(0.0), FCDegreeToRadian(90.0), NO);
	CGPathAddArc(borderPath, NULL, CGRectGetMinX(interiorRect), CGRectGetMaxY(interiorRect), radius, FCDegreeToRadian(90.0), FCDegreeToRadian(180.0), NO);
	
	CGContextBeginPath(maskedContextRef);
	CGContextAddPath(maskedContextRef, borderPath);
	CGContextClosePath(maskedContextRef);
	CGContextClip(maskedContextRef);
	
	[self drawInRect:dstRect];
	
	maskedImage = UIGraphicsGetImageFromCurrentImageContext();
	//CGContextRestoreGState(maskedContextRef);
	UIGraphicsEndImageContext();
	CGPathRelease(borderPath);
	
	return maskedImage;
}
@end

