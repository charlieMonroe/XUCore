// 
// FCLog.h
// 
// Created by Charlie Monroe
// 
// Copyright (c) 2010-14 Charlie Monroe Software. All rights reserved.
// 

/*
 * This file contains several macros and functions that support session-logging.
 *
 * Use mainly FCLog.
 */


#import <Foundation/Foundation.h>

#ifndef  __valist_nonnull
	#if TARGET_OS_IPHONE
		#define __valist_nonnull
	#else
		#define __valist_nonnull
	#endif
#endif

#ifdef __cplusplus
extern "C" {
#endif

	#define __FCFUNCTION__ [[NSString stringWithFormat:@"%s:%d", __FUNCTION__, __LINE__] UTF8String]
	#define FCFunctionStringWithRealClass [NSString stringWithFormat:@"[%@ %@]", [self class], NSStringFromSelector(_cmd)]
	#define FCLog(format...)	{\
							if (FCShouldLog()){	\
								_FCLog(format); \
							} \
						}
	
	NS_SWIFT_UNAVAILABLE("Use XULog instead.") void _FCLog(NSString * __nonnull format, ...) __attribute__((format(__NSString__, 1, 2)));
	NS_SWIFT_UNAVAILABLE("Use XULog instead.") void FCLogv(NSString * __nonnull format, va_list __valist_nonnull args) __attribute__((format(__NSString__, 1, 0)));

	NS_SWIFT_UNAVAILABLE("Use XULog instead.") void FCForceSetDebugging(BOOL debug);
	NS_SWIFT_UNAVAILABLE("Use XULog instead.") BOOL FCShouldLog(void);
	NS_SWIFT_UNAVAILABLE("Use XULog instead.") void FCForceLog(NSString * __nonnull format, ...) __attribute__((format(__NSString__, 1, 2)));
	
	NS_SWIFT_UNAVAILABLE("Use XULog instead.") NSString * __nonnull FCLogFilePath(void);
	NS_SWIFT_UNAVAILABLE("Use XULog instead.") void FCClearLog(void);
	
	/* Returns nil if nothing ever got logged. */
	NS_SWIFT_UNAVAILABLE("Use XULog instead.") NSDate * __nullable FCLastLogDate(void);
	
	NS_SWIFT_UNAVAILABLE("Use XULog instead.") void FCLogStacktrace(NSString * __nonnull comment);
	NS_SWIFT_UNAVAILABLE("Use XULog instead.") NSString * __nonnull FCStacktraceString(void);
	NS_SWIFT_UNAVAILABLE("Use XULog instead.") NSString * __nonnull FCStacktraceStringFromException(NSException * __nonnull exception);
	
	/** This notification is posted upon FCForceSetDebugging(). This allows
	 * classes detect that debug logging was turned on and log something.
	 */
	NS_SWIFT_UNAVAILABLE("Use XULog instead.") extern NSString * __nonnull const FCLoggingStatusChangedNotification;
	
	
	/// This is a private function for Swift's version of FCLog (XULog), which
	/// is needed for enabling both ObjC and Swift debug logging at once. Should
	/// only be called by Swift's XUForceSetDebugging().
	extern void __FCLogSetShouldLog(BOOL log);

#ifdef __cplusplus
}
#endif

