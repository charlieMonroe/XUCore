// 
// FCInAppPurchaseManager.h
// 
// Created by Charlie Monroe
// 
// Copyright (c) 2010-13 Fuel Collective, LLC. All rights reserved.
// 


#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>

@interface FCInAppPurchaseManager : NSObject <SKPaymentTransactionObserver, SKProductsRequestDelegate> {
@public
	NSMutableArray *_products;
	NSMutableArray *_purchases;
	SKRequest *_loadRequest;
}

+(FCInAppPurchaseManager*)sharedManager;

-(void)buyProduct:(SKProduct*)product;
-(NSArray*)productsAvailableForPurchase;// Doesn't include the already purchased products
-(NSArray*)purchasedIdentifiers;
-(void)reloadProductsAvailableForPurchase;
-(void)restorePurchases;
-(void)save;

@end


@interface FCTestProduct : NSObject 

-(NSNumber*)price;
-(NSLocale*)priceLocale;

@property (readwrite, assign, getter = isBought) BOOL bought;
@property (readwrite, strong) NSString *productIdentifier;
@property (readwrite, strong) NSString *localizedTitle;

@end



extern NSString *FCInAppPurchaseManagerPurchasesChangedNotification;
extern NSString *FCInAppPurchaseManagerAvailableProductsGotLoadedNotification;


@interface FCInAppPurchaseManager (ApplicationSpecificMethods) 

-(NSArray*)availableApplicationProductIdentifiers;

-(void)couldNotLoadInAppPurchases:(NSError*)error;

// Both methods are ensured to be called on the main thread
-(void)purchaseForProductFailedWithError:(NSError*)error;
-(void)purchaseForProductWasSuccessful:(NSString*)productIdentifier;

@end


