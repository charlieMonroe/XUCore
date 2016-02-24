//
//  XUExceptionHandler.h
//  XUCore
//
//  Created by Charlie Monroe on 11/11/15.
//  Copyright © 2015 Charlie Monroe Software. All rights reserved.
//

#import <Foundation/Foundation.h>

/// Block that is called when catching an exception.
typedef void(^XUExceptionCatchHandler)(NSException * _Nonnull exception);

/// Block that is called within the finally statement.
typedef void(^XUExceptionFinallyHandler)(void);


/// This class allows handling ObjC exceptions using Swift.
@interface XUExceptionHandler : NSObject

/// Initializer. You must supply the blocks when calling performBlock then.
-(nonnull instancetype)init;

/// Designated initializer
-(nonnull instancetype)initWithCatchHandler:(nonnull XUExceptionCatchHandler)catchHandler andFinallyBlock:(nonnull XUExceptionFinallyHandler)finallyBlock;

/// Performs a block within try statement and calls the finallyHandler when executed
/// without an exception. Must be invoked only if the instance has been created
/// with -initWithCatchHandler:andFinallyBlock:
-(void)performBlock:(nonnull void(^)(void))block;

/// Performs the block with custom catch handler and finally block.
-(void)performBlock:(nonnull void(^)(void))block withCatchHandler:(nonnull XUExceptionCatchHandler)catchHandler andFinallyBlock:(nonnull XUExceptionFinallyHandler)finallyBlock;


/// Catch handler.
@property (readonly, nullable, nonatomic) XUExceptionCatchHandler catchHandler;

/// Finally handler.
@property (readonly, nullable, nonatomic) XUExceptionFinallyHandler finallyHandler;

@end
