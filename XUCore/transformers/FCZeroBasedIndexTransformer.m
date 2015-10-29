// 
// FCZeroBasedIndexTransformer.m
// 
// Created by Charlie Monroe
// 
// Copyright (c) 2010-13 Fuel Collective, LLC. All rights reserved.
// 


#import "FCZeroBasedIndexTransformer.h"


@implementation FCZeroBasedIndexTransformer
-(id)reverseTransformedValue:(id)value{
	//We're only accepting numbers
	NSAssert([value isKindOfClass:[NSNumber class]], @"FCZeroBasedIndexTransformer: wrong value type (reverse)");
	return [NSNumber numberWithInt:[value intValue]-1];
}
-(id)transformedValue:(id)value{
	//We're only accepting numbers
	NSAssert([value isKindOfClass:[NSNumber class]], @"FCZeroBasedIndexTransformer: wrong value type");
	return [NSNumber numberWithInt:[value intValue]+1];
}
@end

