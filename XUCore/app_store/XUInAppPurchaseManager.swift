//
//  XUInAppPurchaseManager.swift
//  XUCore
//
//  Created by Charlie Monroe on 11/23/15.
//  Copyright © 2015 Charlie Monroe Software. All rights reserved.
//

import Foundation
import StoreKit

/// Notification posted when the available products did load.
public let XUInAppPurchaseManagerAvailableProductsDidLoadNotification = "XUInAppPurchaseManagerAvailableProductsGotLoadedNotification"

/// Notification posted when a purchase is made, or restored.
public let XUInAppPurchaseManagerPurchasesChangedNotification = "XUInAppPurchaseManagerPurchasesChangedNotification"


private let XUInAppPurchasesDefaultsKey = "XUInAppPurchases"


/// You need to create a delegate and implement all methods and properties.
public protocol XUInAppPurchaseManagerDelegate: AnyObject {
	
	/// Return a list of available identifiers. This is then checked against
	/// what AppStore returns. Allows the app not to list products that are
	/// not available in this version of the app (example).
	var availableProductIdentifiers: [String] { get }
	
	/// This method is called when a purchase is successful. Ensured to be called
	/// on the main thread.
	func inAppPurchaseManager(manager: XUInAppPurchaseManager, didPurchaseProductWithIdentifier identifier: String)
	
	/// This is called when the in-app purchase manager fails to load in-app 
	/// purchases.
	func inAppPurchaseManager(manager: XUInAppPurchaseManager, failedToLoadInAppPurchasesWithError error: NSError?)

	/// This method is called when a purchase is not successful. Ensured to be
	/// called on the main thread.
	func inAppPurchaseManager(manager: XUInAppPurchaseManager, failedToPurchaseProductWithIdentifier identifier: String, error: NSError)
	
	/// This method is called when a purchase restore is not successful. Ensured
	/// to be called on the main thread.
	func inAppPurchaseManager(manager: XUInAppPurchaseManager, failedToRestorePurchasesWithError error: NSError)
	
	/// This method is called when a purchase restore is successful. Ensured
	/// to be called on the main thread.
	func inAppPurchaseManagerDidRestorePurchases(manager: XUInAppPurchaseManager)
	
}

public class XUInAppPurchaseManager: NSObject, SKPaymentTransactionObserver, SKRequestDelegate {

	/// You need to call this prior to calling sharedManager. Do not call this
	/// unless the current application setup is set to AppStore.
	public class func createSharedManagerWithDelegate(delegate: XUInAppPurchaseManagerDelegate) {
		if !XUApplicationSetup.sharedSetup.AppStoreBuild {
			NSException(name: NSInternalInconsistencyException, reason: "Trying to create in-app purchase manager, while this is not an AppStore build.", userInfo: nil).raise()
		}
		
		sharedManager = XUInAppPurchaseManager(delegate: delegate)
	}
	
	/// This is the shared instance of the manager. Make sure that you call
	/// createSharedManagerWithDelegate() before using this!
	public private(set) static var sharedManager: XUInAppPurchaseManager!
	
	
	private var _loadRequest: SKRequest?
	
	/// The delegate. Unlike the convention, the manager keeps a strong reference
	/// to the delegate for two reasons:
	///
	/// - the delegate is required. Weak implicates nullable.
	/// - the manager is a singleton, hence there is no reason for you to keep
	///		reference to it, hence no retain cycles should be created.
	public let delegate: XUInAppPurchaseManagerDelegate
	
	/// Products available for purchse.
	public private(set) var productsAvailableForPurchase: [SKProduct] = [ ]
	
	/// A list of identifiers of purchased products.
	public private(set) var purchasedProductsIdentifiers: [String] = [ ]
	
	
	/// Called from a notification, so that we remove self from observers when the
	/// app is about to terminate.
	@objc private func _removeAsObserver(sender: AnyObject?) {
		SKPaymentQueue.defaultQueue().removeTransactionObserver(self)
	}
	
	deinit {
		NSNotificationCenter.defaultCenter().removeObserver(self)
	}
	
	private init(delegate: XUInAppPurchaseManagerDelegate) {
		self.delegate = delegate
		
		super.init()
		
		SKPaymentQueue.defaultQueue().addTransactionObserver(self)
		
		if let savedPurchases = NSUserDefaults.standardUserDefaults().arrayForKey(XUInAppPurchasesDefaultsKey) as? [String] {
			let allowedIdentifiers = self.delegate.availableProductIdentifiers
			for hashedIdentifier in savedPurchases {
				for inAppPurchaseID in allowedIdentifiers {
					let hashedInAppIdentifier = inAppPurchaseID + NSProcessInfo.processInfo().processName.MD5Digest.MD5Digest
					if hashedInAppIdentifier == hashedIdentifier && !self.purchasedProductsIdentifiers.contains(inAppPurchaseID) {
						self.purchasedProductsIdentifiers.append(inAppPurchaseID)
					}
				}
			}
			
			XULog("Restored in-app purchases: \(purchasedProductsIdentifiers)")
		}else{
			XULog("NULL in-app purchases data")
		}
		
		self.reloadProductsAvailableForPurchase()
		
		#if os(iOS)
			let transactions = SKPaymentQueue.defaultQueue().transactions
		#else
			let transactions = SKPaymentQueue.defaultQueue().transactions ?? [ ]
		#endif

		if transactions.count > 0 {
			for transaction in transactions {
				SKPaymentQueue.defaultQueue().finishTransaction(transaction)
			}
		}
		
		#if os(iOS)
			let notificationName = UIApplicationWillTerminateNotification
		#else
			let notificationName = NSApplicationWillTerminateNotification
		#endif
		NSNotificationCenter.defaultCenter().addObserver(self, selector: "save", name: notificationName, object: nil)
		NSNotificationCenter.defaultCenter().addObserver(self, selector: "_removeAsObserver:", name: notificationName, object: nil)
	}
	
	public func paymentQueue(queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
		XULog("Payment queue got updated with transactions \(transactions)")
		
		for transaction in transactions {
			let purchasedProductIdentifier = transaction.payment.productIdentifier
			
			XULog("\(transaction.payment.productIdentifier), state \(transaction.transactionState)")
			
			switch transaction.transactionState {
				case SKPaymentTransactionStateFailed:
					if let error = transaction.error {
						XU_PERFORM_BLOCK_ON_MAIN_THREAD({ () -> Void in
							self.delegate.inAppPurchaseManager(self, failedToPurchaseProductWithIdentifier: purchasedProductIdentifier, error: error)
						})
					}
					SKPaymentQueue.defaultQueue().finishTransaction(transaction)
					break
				case SKPaymentTransactionStatePurchasing:
					// Nothing really to be done, either failed or hasn't been processed yet
					break
				case SKPaymentTransactionStatePurchased: fallthrough
				case SKPaymentTransactionStateRestored:
					// Add to purchased items
					XULog("Purchased item with identifier \(purchasedProductIdentifier)")
					if !self.purchasedProductsIdentifiers.contains(purchasedProductIdentifier) {
						self.purchasedProductsIdentifiers.append(purchasedProductIdentifier)
					}
					
					SKPaymentQueue.defaultQueue().finishTransaction(transaction)
					if transaction.transactionState != SKPaymentTransactionStateRestored {
						XU_PERFORM_BLOCK_ON_MAIN_THREAD {
							self.delegate.inAppPurchaseManager(self, didPurchaseProductWithIdentifier: purchasedProductIdentifier)
						}
					}
					break
				default:
					break
			}
		}
		
		self.save()
		
		NSNotificationCenter.defaultCenter().postNotificationName(XUInAppPurchaseManagerPurchasesChangedNotification, object: self)
	}
	
	
	public func paymentQueue(queue: SKPaymentQueue, restoreCompletedTransactionsFailedWithError error: NSError) {
		XULog("Restoration failed with an error \(error)")
		
		XU_PERFORM_BLOCK_ON_MAIN_THREAD { () -> Void in
			self.delegate.inAppPurchaseManager(self, failedToRestorePurchasesWithError: error)
		}
	}
	
	public func paymentQueueRestoreCompletedTransactionsFinished(queue: SKPaymentQueue) {
		XULog("Finished restoration.")
		
		XU_PERFORM_BLOCK_ON_MAIN_THREAD { () -> Void in
			self.delegate.inAppPurchaseManagerDidRestorePurchases(self)
		}
	}
	
	public func productsRequest(request: SKProductsRequest, didReceiveResponse response: SKProductsResponse) {
		if let products = response.products {
			if products.count > 0 {
				XULog("Found new product identifiers \(products)")
				self.productsAvailableForPurchase += products
			}
		}
		
		NSNotificationCenter.defaultCenter().postNotificationName(XUInAppPurchaseManagerAvailableProductsDidLoadNotification, object: self)
		
		// Product was not found in the App Store
		if let invalidProductIdentifiers = response.invalidProductIdentifiers {
			if invalidProductIdentifiers.count > 0 {
				XULog("Invalid product identifiers \(invalidProductIdentifiers)")
			}
		}
		
		_loadRequest = nil
	}
	
	/// Starts a purchase. This is asynchronous and the delegate is notified about
	/// the outcome.
	public func purchaseProduct(product: SKProduct) {
		#if os(iOS)
			let payment = SKPayment(product: product)
		#else
			let payment = SKPayment.paymentWithProduct(product) as! SKPayment
		#endif
		
		SKPaymentQueue.defaultQueue().addPayment(payment)
	}
	
	/// Reloads products available for purchase. Usually is done automatically,
	/// but you may re-trigger this e.g. on network failure.
	public func reloadProductsAvailableForPurchase() {
		if _loadRequest != nil {
			// Already loading
			return
		}
		
		_loadRequest = SKProductsRequest(productIdentifiers: Set<NSObject>(arrayLiteral: self.delegate.availableProductIdentifiers))
		_loadRequest?.delegate = self
		_loadRequest?.start()
	}
	
	#if os(iOS)
	public func request(request: SKRequest, didFailWithError error: NSError) {
		XULog("An error getting products occurred \(error)")
		
		_loadRequest = nil
		
		self.delegate.inAppPurchaseManager(self, failedToLoadInAppPurchasesWithError: error)
	}
	#else
	public func request(request: SKRequest, didFailWithError error: NSError?) {
		XULog("An error getting products occurred \(error)")
		
		_loadRequest = nil
		
		self.delegate.inAppPurchaseManager(self, failedToLoadInAppPurchasesWithError: error)
	}
	#endif
	
	/// Starts restoration of purchases. See delegate methods for callbacks.
	public func restorePurchases() {
		SKPaymentQueue.defaultQueue().restoreCompletedTransactions()
	}
	
	/// Saves the in-app purchases. Seldomly needed to be called manually.
	public func save() {
		XULog("Saving in app purchases \(self.purchasedProductsIdentifiers)")
		
		let hashedIdentifiers = self.purchasedProductsIdentifiers.map { (identifier) -> String in
			return identifier + NSProcessInfo.processInfo().processName.MD5Digest.MD5Digest
		}
		
		NSUserDefaults.standardUserDefaults().setObject(hashedIdentifiers, forKey: XUInAppPurchasesDefaultsKey)
		NSUserDefaults.standardUserDefaults().synchronize()
		
		XULog("In app purchases saved successfully")
	}
	
	
}


