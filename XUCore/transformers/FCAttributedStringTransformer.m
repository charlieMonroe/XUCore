// 
// FCAttributedStringTransformer.m
// 
// Created by Charlie Monroe
// 
// Copyright (c) 2010-13 Fuel Collective, LLC. All rights reserved.
// 


#import "FCAttributedStringTransformer.h"

@implementation FCAttributedStringTransformer

-(id)reverseTransformedValue:(id)value{
	if (value == nil){
		value = @"";
	}
	if ([value isKindOfClass:[NSString class]]){
		return value;
	}
	return [value string];
}
-(id)transformedValue:(id)value{
	if (value == nil){
		value = @"";
	}
	if ([value isKindOfClass:[NSAttributedString class]]){
		return value;
	}
	return [[NSAttributedString alloc] initWithString:value];
}

@end

