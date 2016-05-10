//
//  _XUBacktrace.h
//  XUCore
//
//  Created by Charlie Monroe on 5/10/16.
//  Copyright © 2016 Charlie Monroe Software. All rights reserved.
//

#import <Foundation/Foundation.h>

/// This gives access to the backtrace_symbols function in Swift.
@interface _XUBacktrace : NSObject

/// Returns a backtrace string for addresses.
+(nonnull NSArray<NSString *> *)backtraceStringForAddresses:(nonnull NSArray<NSNumber *> *)addresses;

@end
