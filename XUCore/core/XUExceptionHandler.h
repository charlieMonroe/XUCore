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

/// Designated initializer
-(nonnull instancetype)initWithCatchHandler:(nonnull XUExceptionCatchHandler)catchHandler andFinallyBlock:(nonnull XUExceptionFinallyHandler)finallyBlock;

/// Performs a block within try statement and calls the finallyHandler when executed
/// without an exception
-(void)performBlock:(nonnull void(^)(void))block;


/// Catch handler.
@property (readonly, nonnull, nonatomic) XUExceptionCatchHandler catchHandler;

/// Finally handler.
@property (readonly, nonnull, nonatomic) XUExceptionFinallyHandler finallyHandler;

@end
