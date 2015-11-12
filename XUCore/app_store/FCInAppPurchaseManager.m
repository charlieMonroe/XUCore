// 
// FCInAppPurchaseManager.m
// 
// Created by Charlie Monroe
// 
// Copyright (c) 2010-13 Fuel Collective, LLC. All rights reserved.
// 


#import "FCInAppPurchaseManager.h"
#import "NSStringAdditions.h"

#import "FCLog.h"

static NSString *FCInAppPurchasesDefaultsKey = @"FCInAppPurchases";
NSString *FCInAppPurchaseManagerPurchasesChangedNotification = @"FCInAppPurchaseManagerPurchasesChangedNotification";
NSString *FCInAppPurchaseManagerAvailableProductsGotLoadedNotification = @"FCInAppPurchaseManagerAvailableProductsGotLoadedNotification";

@implementation FCTestProduct

@synthesize productIdentifier, localizedTitle, bought;

-(NSString *)description{
	return [NSString stringWithFormat:@"%@ - %@: %@", [super description], [self localizedTitle], [self productIdentifier]];
}
-(NSNumber*)price{
	return [NSNumber numberWithFloat:4.99];
}
-(NSLocale *)priceLocale{
	return [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
}

@end

@implementation FCInAppPurchaseManager

+(void)initialize{
	if (self == [FCInAppPurchaseManager class]){
		// Automatically load self
		@autoreleasepool {
			[self sharedManager];
		}
	}
}
+(FCInAppPurchaseManager *)sharedManager{
#if FC_APP_STORE_BUILD
	static FCInAppPurchaseManager *_sharedManager = nil;
	if (_sharedManager == nil){
		_sharedManager = [[FCInAppPurchaseManager alloc] init];
	}
	return _sharedManager;
#else
	return nil;
#endif
}


-(void)_removeAsObserver:(id)sender{
	[[SKPaymentQueue defaultQueue] removeTransactionObserver:self];
}
-(NSArray*)productsAvailableForPurchase{
	return _products;
}
-(void)buyProduct:(SKProduct*)product{
	SKPayment *payment = [SKPayment paymentWithProduct:product];
	[[SKPaymentQueue defaultQueue] addPayment:payment];
}
-(void)dealloc{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}
-(id)init{
	self = [super init];
	if (self) {
		[[SKPaymentQueue defaultQueue] addTransactionObserver:self];
		
		NSArray *savedPurchases = [[NSUserDefaults standardUserDefaults] objectForKey:FCInAppPurchasesDefaultsKey];
		if (savedPurchases != nil && [savedPurchases isKindOfClass:[NSArray class]]){
			_purchases = [[NSMutableArray alloc] initWithCapacity:[savedPurchases count]];
			NSArray *allowedIdentifiers = [self availableApplicationProductIdentifiers];
			for (NSString *hashedIdentifier in savedPurchases){
				for (NSString *inAppPurchaseID in allowedIdentifiers){
					NSString *hashedInAppIdentifier = [[[inAppPurchaseID stringByAppendingString:[[NSProcessInfo processInfo] processName]] MD5Digest] MD5Digest];
					if ([hashedInAppIdentifier isEqualToString:hashedIdentifier] && ![_purchases containsObject:inAppPurchaseID]){
						[_purchases addObject:inAppPurchaseID];
					}
				}
			}
			FCLog(@"%s - restored in-app purchases: %@", __FCFUNCTION__, _purchases);
		}else{
			FCLog(@"%s - NULL in-app purchases data", __FCFUNCTION__);
			_purchases = [[NSMutableArray alloc] init];
		}
		
		NSArray *identifiers = [self availableApplicationProductIdentifiers];
		_products = [[NSMutableArray alloc] initWithCapacity:[identifiers count]];
		
		[self reloadProductsAvailableForPurchase];
		
		if ([[[SKPaymentQueue defaultQueue] transactions] count] > 0){
			for (id transaction in [[SKPaymentQueue defaultQueue] transactions]){
				[[SKPaymentQueue defaultQueue] finishTransaction:transaction];
			}
		}
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(save) name:
									#if TARGET_OS_IPHONE
										UIApplicationWillTerminateNotification
									#else
										NSApplicationWillTerminateNotification
									#endif
							   object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_removeAsObserver:) name:
								#if TARGET_OS_IPHONE
										 UIApplicationWillTerminateNotification
								#else
										 NSApplicationWillTerminateNotification
								#endif
							   object:nil];
	}
	
	return self;
}
-(void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions{
	FCLog(@"%s - payment queue got updated with transactions %@", __FCFUNCTION__, transactions);
	for (SKPaymentTransaction *transaction in transactions){
		NSString *purchasedProductIdentifier = [[transaction payment] productIdentifier];
		FCLog(@"%s - %@, state %i", __FCFUNCTION__, [[transaction payment] productIdentifier], (int)[transaction transactionState]);
		switch ([transaction transactionState]) {
			case SKPaymentTransactionStateFailed:
				if ([transaction error] != nil){
					[self performSelectorOnMainThread:@selector(purchaseForProductFailedWithError:) withObject:[transaction error] waitUntilDone:YES];
				}
				[[SKPaymentQueue defaultQueue]  finishTransaction:transaction];
				break;
			case SKPaymentTransactionStatePurchasing:
				// Nothing really to be done, either failed or hasn't been processed yet
				break;
			case SKPaymentTransactionStatePurchased:
			case SKPaymentTransactionStateRestored:
				// Add to purchased items
				FCLog(@"%s - bought item with identifier %@", __FCFUNCTION__, purchasedProductIdentifier);
				if (![_purchases containsObject:purchasedProductIdentifier]){
					[_purchases addObject:purchasedProductIdentifier];
				}
				[[SKPaymentQueue defaultQueue] finishTransaction:transaction];
				if ([transaction transactionState] != SKPaymentTransactionStateRestored){
					[self performSelectorOnMainThread:@selector(purchaseForProductWasSuccessful:) withObject:purchasedProductIdentifier waitUntilDone:YES];
				}
				break;
			default:
				break;
		}
	}
	
	[self save];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:FCInAppPurchaseManagerPurchasesChangedNotification object:nil];
}
-(void)paymentQueue:(SKPaymentQueue *)queue restoreCompletedTransactionsFailedWithError:(NSError *)error{
	FCLog(@"%s - restoration failed with an error %@", __FCFUNCTION__, error);
	
	[self performSelectorOnMainThread:@selector(purchaseForProductFailedWithError:) withObject:error waitUntilDone:YES];
}
-(void)paymentQueueRestoreCompletedTransactionsFinished:(SKPaymentQueue *)queue{
	FCLog(@"%s - finished restoration", __FCFUNCTION__);
	[self performSelectorOnMainThread:@selector(purchaseForProductWasSuccessful:) withObject:@"" waitUntilDone:YES];
}
-(void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response{
	if ([[response products] count] > 0){
		FCLog(@"%s - found new product identifiers %@", __FCFUNCTION__, [response products]);
		[_products addObjectsFromArray:[response products]];
	}
	
	[[NSNotificationCenter defaultCenter] postNotificationName:FCInAppPurchaseManagerAvailableProductsGotLoadedNotification object:nil];
	
	//Product was not found in the App Store
	if ([[response invalidProductIdentifiers] count] > 0){
		FCLog(@"%s - invalid product identifiers %@", __FCFUNCTION__, [response invalidProductIdentifiers]);
	}
	
	_loadRequest = nil;
}

-(void)reloadProductsAvailableForPurchase{
	if (_loadRequest != nil){
		// Already loading
		return;
	}
	
	_loadRequest = [[SKProductsRequest alloc] initWithProductIdentifiers:[NSSet setWithArray:[self availableApplicationProductIdentifiers]]];
	[_loadRequest setDelegate:self];
	[_loadRequest start];
}
-(void)request:(SKRequest *)request didFailWithError:(NSError *)error{
	FCLog(@"%s - an error getting products occurred %@", __FCFUNCTION__, [error localizedDescription]);
	_loadRequest = nil;
	
	if ([self respondsToSelector:@selector(couldNotLoadInAppPurchases:)]){
		[self couldNotLoadInAppPurchases:error];
	}
}
-(NSArray *)purchasedIdentifiers{
	return _purchases;
}
-(void)restorePurchases{
	[[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
}
-(void)save{
	FCLog(@"%s - saving in app purchases %@", __FCFUNCTION__, _purchases);
	
	NSMutableArray *hashedIdentifiers = [NSMutableArray arrayWithCapacity:[_purchases count]];
	for (NSString *identifier in _purchases){
		NSString *hashedIdentifier = [[[identifier stringByAppendingString:[[NSProcessInfo processInfo] processName]] MD5Digest] MD5Digest];
		[hashedIdentifiers addObject:hashedIdentifier];
	}

	[[NSUserDefaults standardUserDefaults] setObject:hashedIdentifiers forKey:FCInAppPurchasesDefaultsKey];
	[[NSUserDefaults standardUserDefaults] synchronize];
	
	FCLog(@"%s - in app purchases saved successfully", __FCFUNCTION__);
}

@end

