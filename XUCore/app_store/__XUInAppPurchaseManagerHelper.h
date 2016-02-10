//
//  __XUInAppPurchaseManagerHelper.h
//  XUCore
//
//  Created by Charlie Monroe on 2/10/16.
//  Copyright © 2016 Charlie Monroe Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@import StoreKit;

/// This is a private class used by XUI
@interface __XUInAppPurchaseManagerHelper : NSObject

+(void)requestProductsWithIdentifiers:(nonnull NSArray<NSString *> *)identifiers withDelegate:(nonnull id<SKProductsRequestDelegate>)delegate;

@end
