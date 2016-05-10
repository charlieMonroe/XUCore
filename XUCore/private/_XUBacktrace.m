//
//  _XUBacktrace.m
//  XUCore
//
//  Created by Charlie Monroe on 5/10/16.
//  Copyright © 2016 Charlie Monroe Software. All rights reserved.
//

#import "_XUBacktrace.h"
#import <execinfo.h>

@implementation _XUBacktrace

+(NSArray<NSString *> *)backtraceStringForAddresses:(NSArray<NSNumber *> *)addresses {
	void* callstack[1024] = {0};
	
	NSInteger counter = 0;
	for (NSNumber *address in addresses) {
		callstack[counter] = [address pointerValue];
		++counter;
	}
	
	char **stack = backtrace_symbols(callstack, (int)[addresses count]);
	if (stack == NULL) {
		return @[];
	}
	
	NSMutableArray<NSString *> *result = [NSMutableArray array];
	for (NSInteger i = 0; i < [addresses count]; ++i) {
		[result addObject:[NSString stringWithUTF8String:stack[i]]];
	}
	
	free(stack);
	
	return result;
}

@end
