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
		#define __valist_nonnull __nonnull
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
	
	void _FCLog(NSString * __nonnull format, ...) __attribute__((format(__NSString__, 1, 2)));
	void FCLogv(NSString * __nonnull format, va_list __valist_nonnull args) __attribute__((format(__NSString__, 1, 0)));

	void FCForceSetDebugging(BOOL debug);
	BOOL FCShouldLog(void);
	void FCForceLog(NSString * __nonnull format, ...) __attribute__((format(__NSString__, 1, 2)));
	
	NSString * __nonnull FCLogFilePath(void);
	void FCClearLog(void);
	
	/* Returns nil if nothing ever got logged. */
	NSDate * __nullable FCLastLogDate(void);
	
	void FCLogStacktrace(NSString * __nonnull comment);
	NSString * __nonnull FCStacktraceString(void);
	NSString * __nonnull FCStacktraceStringFromException(NSException * __nonnull exception);
	
	/** This notification is posted upon FCForceSetDebugging(). This allows
	 * classes detect that debug logging was turned on and log something.
	 */
	extern NSString * __nonnull const FCLoggingStatusChangedNotification;

#ifdef __cplusplus
}
#endif

