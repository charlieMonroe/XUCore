// 
// NSHTTPURLResponse.h
// 
// Created by Charlie Monroe
// 
// Copyright (c) 2010-13 Fuel Collective, LLC. All rights reserved.
// 


#import <Foundation/Foundation.h>


@interface NSHTTPURLResponse (StatusAdditions)
-(BOOL)statusCodeWithin200Range;
@end

