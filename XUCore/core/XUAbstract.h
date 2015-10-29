//
//  XUAbstract.h
//  DownieCore
//
//  Created by Charlie Monroe on 9/3/14.
//  Copyright (c) 2014 Charlie Monroe Software. All rights reserved.
//

#ifndef DownieCore_XUAbstract_h
#define DownieCore_XUAbstract_h

/** This file contains several macros and inline methods that allow easy abstract class
 * implementations.
 *
 * To use this, you must #define XUAbstractExceptionName as a string that is used for
 * throwing exceptions. Then just import this header.
 */

#ifndef XUAbstractExceptionName
	#define XUAbstractExceptionName @"XUAbstractExceptionName"
#endif

/** Used for faking an abstract class on ObjC. */
__attribute__((noreturn))
static inline void _XUThrowAbstractionException(id self, SEL _cmd){
	[self doesNotRecognizeSelector:_cmd];
	@throw [NSException exceptionWithName:XUAbstractExceptionName reason:[NSString stringWithFormat:@"[%@ %@]", [self class], NSStringFromSelector(_cmd)] userInfo:nil];
}

/** Throws an abstraction exception. */
#define XUThrowAbstractionException() _XUThrowAbstractionException(self, _cmd)

/** Generates a body of the abstract method by throwing an exception. */
#define XUGenerateAbstractMethod(methodSig) methodSig{ XUThrowAbstractionException(); }


#endif
