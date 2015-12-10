// 
// FCLog.m
// 
// Created by Charlie Monroe
// 
// Copyright (c) 2010-14 Charlie Monroe Software. All rights reserved.
// 


#import "FCLog.h"

#import <XUCore/XUCore-Swift.h>

NSString * __nonnull const FCLoggingStatusChangedNotification = @"FCLoggingStatusChangedNotification";

static BOOL _didCachePreferences = NO;
static BOOL _cachedPreferences = NO;
static BOOL _didRedirectToLogFile = NO;

static FILE *_logFile;

static NSTimeInterval _lastLogTimeInterval;

NSString *FCLogFilePath(){
	//The app identifier
	NSString *appIdentifier = [[NSBundle mainBundle] bundleIdentifier];
	if (appIdentifier == nil){
		//Probably a process
		appIdentifier = [[NSProcessInfo processInfo] processName];
	}
	
	//Make sure the logs directory exists
	NSString *logFolder = [[NSString stringWithFormat:@"~/Library/Application Support/%@/Logs/", appIdentifier] stringByExpandingTildeInPath];
	NSString *logFile = [logFolder stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.log", appIdentifier]];
	[[NSFileManager defaultManager] createDirectoryAtPath:logFolder withIntermediateDirectories:YES attributes:nil error:nil];
	
	return logFile;
}

static inline void _FCCachePreferences(){
	if (!_didCachePreferences){
		_didCachePreferences = YES;
		_cachedPreferences = [[NSUserDefaults standardUserDefaults] boolForKey:@"FCLoggingEnabled"];
	}
}

static BOOL _FCRunningDevelopmentComputer(){
	#if !defined(DEBUG)
		#define DEBUG_REDEFINED
		#define DEBUG 0
	#endif
	return ([[[[NSProcessInfo processInfo] environment] objectForKey:@"PWD"] hasPrefix:@"/Users/oli/"]
		|| [[[[NSProcessInfo processInfo] environment] objectForKey:@"PWD"] hasPrefix:@"/Users/charlie/"]
		|| [[[[NSProcessInfo processInfo] environment] objectForKey:@"PWD"] hasPrefix:@"/Users/charliemonroe/"]
		|| TARGET_IPHONE_SIMULATOR
		|| (TARGET_OS_IPHONE && DEBUG));
	#if defined(DEBUG_REDEFINED)
		#undef DEBUG_REDEFINED
		#undef DEBUG
	#endif
}

static void _FCRedirectToLogFile() {
	// DO NOT LOG ANYTHING IN THIS FUNCTION,
	// AS YOU'D MAKE AN INFINITE LOOP!
	
	if (_FCRunningDevelopmentComputer()){
		return;
	}
	
	NSString *logFile = FCLogFilePath();
	
	// Try to create the log file
	if (![[NSFileManager defaultManager] fileExistsAtPath:logFile]){
		[(NSData*)[NSData data] writeToFile:logFile atomically:YES];
	}
	
	//Open the file
	_logFile = fopen([logFile fileSystemRepresentation], "a+");
	if (_logFile != NULL){
		//Making sure it exists
		int fileDesc = fileno(_logFile);
		dup2(fileDesc, STDOUT_FILENO);
		dup2(fileDesc, STDERR_FILENO);
		
		_didRedirectToLogFile = YES;
	}
}

static void _FCStartNewSession() {
	NSProcessInfo *processInfo = [NSProcessInfo processInfo];
	
	NSString *version = [[XUApplicationSetup sharedSetup] applicationVersionNumber];
	NSString *buildNumber = [[XUApplicationSetup sharedSetup] applicationBuildNumber];
	NSString *buildType = [[XUApplicationSetup sharedSetup] AppStoreBuild] ? @"AppStore" : @"Trial";
	
	NSLog(@"\n\n\n============== Starting a new %@ session (version %@[%@], %@) ==============", [processInfo processName], version, buildNumber, buildType);
}

static void _FCLogInitializer() __attribute__ ((constructor));
static void _FCLogInitializer() {
	if (_didCachePreferences){
		// No double-initialization
		return;
	}
	
	//Don't redirect the log on my computer
	if (_FCRunningDevelopmentComputer()){
		_didCachePreferences = YES;
		_cachedPreferences = YES;
		return;
	}
	
	_FCCachePreferences();
	if (_cachedPreferences){
		_FCRedirectToLogFile();
		_FCStartNewSession();
	}
}

void __FCLogSetShouldLog(BOOL log) {
	if (log && !_didRedirectToLogFile){
		_FCRedirectToLogFile();
		_FCStartNewSession();
	}
	
	BOOL didChange = log != _cachedPreferences;
	
	_cachedPreferences = log;
	_didCachePreferences = YES; //Already cached hence
	
	if (didChange) {
		[[NSNotificationCenter defaultCenter] postNotificationName:FCLoggingStatusChangedNotification object:nil];
	}
}

void FCForceSetDebugging(BOOL debug){
	__FCLogSetShouldLog(debug);
	
	[__XULogBridge setShouldLog:debug];
}

BOOL FCShouldLog(){
	return _cachedPreferences;
}

void FCForceLog(NSString *format, ...){
	BOOL originalCachedPrefs = _cachedPreferences;
	FCForceSetDebugging(YES);
	
	va_list argList;
	va_start(argList, format);
	NSLogv(format, argList);
	va_end(argList);

	_cachedPreferences = originalCachedPrefs;
}

void _FCLog(NSString *format, ...){
	if (!_didCachePreferences){
		_FCLogInitializer();
	}
	if (_cachedPreferences){
		va_list argList;
		va_start(argList, format);
		NSLogv(format, argList);
		va_end(argList);
		
		_lastLogTimeInterval = [NSDate timeIntervalSinceReferenceDate];
	}
}

void FCLogv(NSString *format, va_list args){
	if (_cachedPreferences){
		NSLogv(format, args);
	}
}

static inline NSString *__FCStacktraceStringFromSymbols(NSArray *symbols){
	NSMutableString *trace = [NSMutableString string];
	BOOL firstLine = YES;
	for (NSString *symbol in symbols) {
		if (firstLine){
			[trace appendString:symbol];
			firstLine = NO;
		}else{
			[trace appendFormat:@"\n%@", symbol];
		}
	}
	return trace;
}

NSString *FCStacktraceString(void){
	return __FCStacktraceStringFromSymbols([NSThread callStackSymbols]);
}

NSString *FCStacktraceStringFromException(NSException *exception){
	return __FCStacktraceStringFromSymbols([exception callStackSymbols]);
}

void FCLogStacktrace(NSString *comment){
	FCLog(@"%@: %@", comment, FCStacktraceString());
}

void FCClearLog(void){
	if (_logFile != NULL){
		fclose(_logFile);
		_logFile = NULL;
		
		[[NSFileManager defaultManager] removeItemAtPath:FCLogFilePath() error:NULL];
		
		_didRedirectToLogFile = NO;
		
		if (_cachedPreferences){
			_FCRedirectToLogFile();
			_FCStartNewSession();
		}
	}
}

NSDate *FCLastLogDate(void){
	if (_lastLogTimeInterval == 0.0){
		return nil;
	}
	return [NSDate dateWithTimeIntervalSinceReferenceDate:_lastLogTimeInterval];
}



