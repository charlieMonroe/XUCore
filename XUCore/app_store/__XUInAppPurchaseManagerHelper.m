//
//  __XUInAppPurchaseManagerHelper.m
//  XUCore
//
//  Created by Charlie Monroe on 2/10/16.
//  Copyright © 2016 Charlie Monroe Software. All rights reserved.
//

#import "__XUInAppPurchaseManagerHelper.h"

@implementation __XUInAppPurchaseManagerHelper

+(void)requestProductsWithIdentifiers:(NSArray<NSString *> *)identifiers withDelegate:(id<SKProductsRequestDelegate>)delegate {
	SKProductsRequest *request = [[SKProductsRequest alloc] initWithProductIdentifiers:[NSSet setWithArray:identifiers]];
	[request setDelegate:delegate];
	[request start];
}

@end
