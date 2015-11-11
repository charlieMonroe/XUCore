//
//  NSLockAdditions.m
//
//  Created by Charlie Monroe on 2/20/14.
//  Copyright (c) 2014 Charlie Monroe Software. All rights reserved.
//

#import "NSRecursiveLockAdditions.h"

@implementation NSRecursiveLock (Additions)

-(void)performLockedBlock:(void (^)(void))block{
	[self lock];
	
	@try {
		block();
	}@catch (NSException *exception) {
		[self unlock];
		@throw exception;
	}

	[self unlock];
}

@end
