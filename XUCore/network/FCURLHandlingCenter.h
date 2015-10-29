// 
// FCURLHandlingCenter.h
// 
// Created by Charlie Monroe
// 
// Copyright (c) 2010-13 Fuel Collective, LLC. All rights reserved.
// 


#import <Foundation/Foundation.h>

@protocol FCURLHandler <NSObject>
-(void)handlerShouldProcessURL:(nonnull NSURL *)url;
@end

@interface FCURLHandlingCenter : NSObject {
	NSMutableDictionary *_handlers;
}

+(nonnull instancetype)defaultCenter;

-(void)addHandler:(nonnull id <FCURLHandler>)handler forURLScheme:(nonnull NSString *)scheme;
-(void)removeHandler:(nonnull id <FCURLHandler>)handler;
-(void)removeHandler:(nonnull id <FCURLHandler>)handler forURLScheme:(nonnull NSString *)scheme;

@end

