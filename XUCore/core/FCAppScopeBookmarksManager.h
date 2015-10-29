// 
// FCAppScopeBookmarksManager.h
// 
// Created by Charlie Monroe
// 
// Copyright (c) 2010-13 Fuel Collective, LLC. All rights reserved.
// 


#import <Foundation/Foundation.h>

@interface FCAppScopeBookmarksManager : NSObject {
	NSMutableDictionary *_cache;
}

+(nonnull instancetype)sharedManager;

-(void)setURL:(nonnull NSURL *)url forKey:(nonnull NSString *)defaultsKey;
-(nullable NSURL *)URLForKey:(nonnull NSString *)defaultsKey;

@end

