// 
// FCUniqueStringManager.m
// 
// Created by Charlie Monroe
// 
// Copyright (c) 2010-13 Fuel Collective, LLC. All rights reserved.
// 


#import "FCUniqueStringManager.h"

@implementation FCUniqueStringManager

+(FCUniqueStringManager*)manager{
	static dispatch_once_t once;
	static FCUniqueStringManager *_sharedManager;
	dispatch_once(&once, ^ {
		_sharedManager = [[FCUniqueStringManager alloc] init];
        });
	return _sharedManager;
}

-(NSArray *)allCachedStrings{
	return [_stringHolder allKeys];
}
-(id)init{
	if ((self = [super init]) != nil){
		_stringHolder = [[NSMutableDictionary alloc] initWithCapacity:1];
	}
	return self;
}
-(NSUInteger)numberOfCachedStrings{
	return [_stringHolder count];
}
-(NSString *)uniqueStringForString:(NSString *)string{
	NSString *cachedString = [_stringHolder objectForKey:string];
	if (cachedString == nil){
		[_stringHolder setObject:string forKey:string];
		cachedString = string;
	}
	return cachedString;
}

@end

