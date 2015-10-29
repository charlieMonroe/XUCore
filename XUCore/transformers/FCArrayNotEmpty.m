// 
// FCArrayNotEmpty.m
// 
// Created by Charlie Monroe
// 
// Copyright (c) 2010-13 Fuel Collective, LLC. All rights reserved.
// 


#import "FCArrayNotEmpty.h"


@implementation FCArrayNotEmpty
-(id)transformedValue:(id)value{
	return [NSNumber numberWithBool:[value count] > 0];
}
@end

