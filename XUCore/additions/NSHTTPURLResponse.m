// 
// NSHTTPURLResponse.m
// 
// Created by Charlie Monroe
// 
// Copyright (c) 2010-13 Fuel Collective, LLC. All rights reserved.
// 


#import "NSHTTPURLResponse.h"


@implementation NSHTTPURLResponse (StatusAdditions)
-(BOOL)statusCodeWithin200Range{
	return [self statusCode]>=200 && [self statusCode]<300;
}
@end

