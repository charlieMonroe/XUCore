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
-(instancetype)initWithCatchHandler:(XUExceptionCatchHandler)catchHandler andFinallyBlock:(XUExceptionFinallyHandler)finallyBlock{
	if ((self = [super init]) != nil){
		_catchHandler = catchHandler;
		_finallyHandler = finallyBlock;
	}
	return self;
}
-(void)performBlock:(void (^)(void))block{
	@try {
		block();
	}@catch (NSException *exception) {
		_catchHandler(exception);
	}@finally {
		_finallyHandler();
	}
}
-(void)performBlock:(void (^)(void))block withCatchHandler:(XUExceptionCatchHandler)catchHandler andFinallyBlock:(XUExceptionFinallyHandler)finallyBlock {
	@try {
		block();
	}@catch (NSException *exception) {
		catchHandler(exception);
	}@finally {
		finallyBlock();
	}
}

@end
