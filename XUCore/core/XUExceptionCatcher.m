//
//  XUExceptionHandler.m
//  XUCore
//
//  Created by Charlie Monroe on 11/11/15.
//  Copyright © 2015 Charlie Monroe Software. All rights reserved.
//

#import "XUExceptionCatcher.h"

@implementation XUExceptionCatcher

-(instancetype)init {
	return [super init];
}

+(void)performBlock:(void (^)(void))block withCatchHandler:(XUExceptionCatchHandler)catchHandler andFinallyBlock:(XUExceptionFinallyHandler)finallyBlock {
	@try {
		block();
	} @catch (NSException *exception) {
		catchHandler(exception);
	} @finally {
		finallyBlock();
	}
}

+(void)performBlock:(void (^)(void))block withCatchHandler:(XUExceptionCatchHandler)catchHandler {
	[self performBlock:block withCatchHandler:catchHandler andFinallyBlock:^{
		// No-op
	}];
}

@end
