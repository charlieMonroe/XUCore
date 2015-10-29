//
//  NSLockAdditions.m
//
//  Created by Charlie Monroe on 2/20/14.
//  Copyright (c) 2014 Charlie Monroe Software. All rights reserved.
//

#import "NSLockAdditions.h"

@implementation NSLock (Additions)

-(void)performLockedBlock:(void (^)(void))block{
	[self lock];
	
	block();
	
	[self unlock];
}

@end
