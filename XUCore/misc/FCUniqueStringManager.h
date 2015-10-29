// 
// FCUniqueStringManager.h
// 
// Created by Charlie Monroe
// 
// Copyright (c) 2010-13 Fuel Collective, LLC. All rights reserved.
// 


#import <Foundation/Foundation.h>

@interface FCUniqueStringManager : NSObject {
	NSMutableDictionary *_stringHolder;
}

+(FCUniqueStringManager*)manager;

-(NSArray*)allCachedStrings;
-(NSUInteger)numberOfCachedStrings;
-(NSString*)uniqueStringForString:(NSString*)string;

@end

