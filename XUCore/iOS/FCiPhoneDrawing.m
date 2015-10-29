// 
// FCiPhoneDrawing.m
// 
// Created by Charlie Monroe
// 
// Copyright (c) 2010-13 Fuel Collective, LLC. All rights reserved.
// 

/*
 *  FCiPhoneDrawing.c
 *  Meaty
 *
 *  Created by alto on 11/17/09.
 *  Copyright 2009 FuelCollective. All rights reserved.
 *
 */

#include "FCiPhoneDrawing.h"
#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
	#import <UIKit/UIKit.h>	
#else
	#import <Cocoa/Cocoa.h>
#endif

void CGContextAddRoundedRect (CGContextRef c, CGRect rect, int corner_radius) {  
	int x_left = rect.origin.x;  
	int x_left_center = rect.origin.x + corner_radius;  
	int x_right_center = rect.origin.x + rect.size.width - corner_radius;  
	int x_right = rect.origin.x + rect.size.width;  
	int y_top = rect.origin.y;  
	int y_top_center = rect.origin.y + corner_radius;  
	int y_bottom_center = rect.origin.y + rect.size.height - corner_radius;  
	int y_bottom = rect.origin.y + rect.size.height;  
	
	/* Begin! */  
	CGContextBeginPath(c);  
	CGContextMoveToPoint(c, x_left, y_top_center);  
	
	/* First corner */  
	CGContextAddArcToPoint(c, x_left, y_top, x_left_center, y_top, corner_radius);  
	CGContextAddLineToPoint(c, x_right_center, y_top);  
	
	/* Second corner */  
	CGContextAddArcToPoint(c, x_right, y_top, x_right, y_top_center, corner_radius);  
	CGContextAddLineToPoint(c, x_right, y_bottom_center);  
	
	/* Third corner */  
	CGContextAddArcToPoint(c, x_right, y_bottom, x_right_center, y_bottom, corner_radius);  
	CGContextAddLineToPoint(c, x_left_center, y_bottom);  
	
	/* Fourth corner */  
	CGContextAddArcToPoint(c, x_left, y_bottom, x_left, y_bottom_center, corner_radius);  
	CGContextAddLineToPoint(c, x_left, y_top_center);  
	
	/* Done */  
	CGContextClosePath(c);  
	
}

CGFloat FCDegreeToRadian(CGFloat degrees){
	return degrees * (3.14159 / 180.0);
}
