//
//  XUExceptionHandler.h
//  XUCore
//
//  Created by Charlie Monroe on 11/11/15.
//  Copyright © 2015 Charlie Monroe Software. All rights reserved.
//

@import Foundation;

/// Block that is called when catching an exception.
typedef void(^XUExceptionCatchHandler)(NSException * _Nonnull exception);

/// Block that is called within the finally statement.
typedef void(^XUExceptionFinallyHandler)(void);


/// This class allows handling ObjC exceptions using Swift.
@interface XUExceptionCatcher : NSObject

/// Convenience method when you don't need any finally block.
+(void)performBlock:(nonnull __attribute__((__noescape__)) void(^)(void))block withCatchHandler:(nonnull __attribute__((__noescape__)) XUExceptionCatchHandler)catchHandler;

/// Performs the block with custom catch handler and finally block.
+(void)performBlock:(nonnull __attribute__((__noescape__)) void(^)(void))block withCatchHandler:(nonnull __attribute__((__noescape__)) XUExceptionCatchHandler)catchHandler andFinallyBlock:(nonnull __attribute__((__noescape__)) XUExceptionFinallyHandler)finallyBlock;


/// Will call abort().
-(nonnull instancetype)init NS_UNAVAILABLE;

@end
