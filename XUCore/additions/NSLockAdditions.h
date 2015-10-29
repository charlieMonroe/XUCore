//
//  NSLockAdditions.h
//
//  Created by Charlie Monroe on 2/20/14.
//  Copyright (c) 2014 Charlie Monroe Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSLock (Additions)

/*
 * Performs block while locked. Main advantage is that it catches
 * exceptions, unlocks the lock and then rethrows the exception,
 * thus preventing deadlocks.
 */
-(void)performLockedBlock:(nonnull void(^)(void))block;

@end
