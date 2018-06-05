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
	abort();
}

+(void)performBlock:(__attribute__((__noescape__)) void (^)(void))block withCatchHandler:(__attribute__((__noescape__)) XUExceptionCatchHandler)catchHandler andFinallyBlock:(__attribute__((__noescape__)) XUExceptionFinallyHandler)finallyBlock {
	@try {
		block();
	} @catch (NSException *exception) {
		catchHandler(exception);
	} @finally {
		finallyBlock();
	}
}

+(void)performBlock:(__attribute__((__noescape__)) void (^)(void))block withCatchHandler:(__attribute__((__noescape__)) XUExceptionCatchHandler)catchHandler {
	[self performBlock:block withCatchHandler:catchHandler andFinallyBlock:^{
		// No-op
	}];
}

@end
