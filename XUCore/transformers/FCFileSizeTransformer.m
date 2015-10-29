// 
// FCFileSizeTransformer.m
// 
// Created by Charlie Monroe
// 
// Copyright (c) 2010-13 Fuel Collective, LLC. All rights reserved.
// 


#import "FCFileSizeTransformer.h"

NSString *FCUseBinarySizes = @"FCUseBinarySizes";

static BOOL _cachedBaseSize;
static float kBaseSize;

@implementation FCFileSizeTransformer
-(id)transformedValue:(id)value{
	if (!_cachedBaseSize){
		if ([[NSUserDefaults standardUserDefaults] boolForKey:FCUseBinarySizes]){
			kBaseSize = 1024.0;
		}else{
			kBaseSize = 1000.0;
		}
	}
	
	
	NSNumber *num = value;
	float size = [num floatValue];
	if (num == nil || size < 0){
		return @"-- kB";
	}else if (size<kBaseSize){
		return [NSString stringWithFormat:@"%0.00f B" ,size];
	}else if (size<(kBaseSize * kBaseSize)){
		return [NSString stringWithFormat:@"%0.00f kB",size/kBaseSize];
	}else if (size<(kBaseSize * kBaseSize * kBaseSize)){
		return [NSString stringWithFormat:@"%0.2f MB",(size/kBaseSize)/kBaseSize];
	}else{ // if (size<(kBaseSize * kBaseSize * kBaseSize * kBaseSize))
		return [NSString stringWithFormat:@"%0.2f GB",((size/kBaseSize)/kBaseSize)/kBaseSize];
	}
	return @"-- kB";
}
@end

