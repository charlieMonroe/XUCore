//
//  XUInAppPurchaseManager.swift
//  XUCore
//
//  Created by Charlie Monroe on 11/23/15.
//  Copyright © 2015 Charlie Monroe Software. All rights reserved.
//

import Foundation
import StoreKit

extension Notification.Name {

	/// Notification posted when the available products did load.
	public static let availableProductsDidLoadNotification: Notification.Name = Notification.Name(rawValue: "XUInAppPurchaseManagerAvailableProductsDidLoadNotification")

	/// Notification posted when a purchase is made, or restored.
	public static let purchasesDidChangeNotification: Notification.Name = Notification.Name(rawValue: "XUInAppPurchaseManagerPurchasesDidChangeNotification")

}

public extension Sequence where Iterator.Element: SKProduct {
	
	/// Sorts products by localizedTitle.
	public func sortedByTitle() -> [Iterator.Element] {
		return self.sorted(by: { $0.localizedTitle.compare($1.localizedTitle, options: .caseInsensitive) == .orderedAscending })
	}
	
}

@available(*, unavailable, renamed: "Notification.Name.availableProductsDidLoadNotification")
public let XUInAppPurchaseManagerAvailableProductsDidLoadNotification = Notification.Name.availableProductsDidLoadNotification

@available(*, unavailable, renamed: "Notification.Name.purchasesDidChangeNotification")
public let XUInAppPurchaseManagerPurchasesDidChangeNotification = Notification.Name.purchasesDidChangeNotification

private let XUInAppPurchasesDefaultsKey = "XUInAppPurchases"


/// You need to create a delegate and implement all methods and properties.
@objc public protocol XUInAppPurchaseManagerDelegate: AnyObject {
	
	/// Return a list of available identifiers. This is then checked against
	/// what AppStore returns. Allows the app not to list products that are
	/// not available in this version of the app (example).
	var availableProductIdentifiers: [String] { get }
	
	/// This method is called when a purchase is successful. Ensured to be called
	/// on the main thread.
	func inAppPurchaseManager(_ manager: XUInAppPurchaseManager, didPurchaseProductWithIdentifier identifier: String)
	
	/// This is called when the in-app purchase manager fails to load in-app 
	/// purchases.
	func inAppPurchaseManager(_ manager: XUInAppPurchaseManager, failedToLoadInAppPurchasesWithError error: Error)

	/// This method is called when a purchase is not successful. Ensured to be
	/// called on the main thread.
	func inAppPurchaseManager(_ manager: XUInAppPurchaseManager, failedToPurchaseProductWithIdentifier identifier: String, error: Error)
	
	/// This method is called when a purchase restore is not successful. Ensured
	/// to be called on the main thread.
	func inAppPurchaseManager(_ manager: XUInAppPurchaseManager, failedToRestorePurchasesWithError error: Error)
	
	/// This method is called when a purchase restore is successful. Ensured
	/// to be called on the main thread.
	func inAppPurchaseManagerDidRestorePurchases(_ manager: XUInAppPurchaseManager)
	
}

public final class XUInAppPurchaseManager: NSObject, SKPaymentTransactionObserver, SKRequestDelegate, SKProductsRequestDelegate {

	/// You need to call this prior to calling sharedManager. Do not call this
	/// unless the current application setup is set to AppStore.
	public class func createSharedManagerWithDelegate(_ delegate: XUInAppPurchaseManagerDelegate) {
		if !XUAppSetup.isAppStoreBuild {
			NSException(name: NSExceptionName.internalInconsistencyException, reason: "Trying to create in-app purchase manager, while this is not an AppStore build.", userInfo: nil).raise()
		}
		
		self.sharedManager = XUInAppPurchaseManager(delegate: delegate)
	}
	
	/// This is the shared instance of the manager. Make sure that you call
	/// createSharedManagerWithDelegate() before using this!
	public fileprivate(set) static var sharedManager: XUInAppPurchaseManager!
	
	
	/// The delegate. Unlike the convention, the manager keeps a strong reference
	/// to the delegate for two reasons:
	///
	/// - the delegate is required. Weak implicates nullable.
	/// - the manager is a singleton, hence there is no reason for you to keep
	///		reference to it, hence no retain cycles should be created.
	public let delegate: XUInAppPurchaseManagerDelegate
	
	/// Returns true if the manager is currently loading products.
	public fileprivate(set) var isLoadingProducts: Bool = false
	
	/// Products available for purchse.
	public fileprivate(set) var productsAvailableForPurchase: [SKProduct] = [ ]
	
	/// A list of identifiers of purchased products.
	public fileprivate(set) var purchasedProductIdentifiers: [String] = [ ]
	
	
	/// Called from a notification, so that we remove self from observers when the
	/// app is about to terminate.
	@objc fileprivate func _removeAsObserver(_ sender: AnyObject?) {
		SKPaymentQueue.default().remove(self)
	}
	
	@objc fileprivate func _innerInit() {
		self.reloadProductsAvailableForPurchase()
		
		let transactions = SKPaymentQueue.default().transactions
		if transactions.count > 0 {
			for transaction in transactions {
				SKPaymentQueue.default().finishTransaction(transaction)
			}
		}
	}
	
	deinit {
		NotificationCenter.default.removeObserver(self)
	}
	
	fileprivate init(delegate: XUInAppPurchaseManagerDelegate) {
		self.delegate = delegate
		
		super.init()
		
		SKPaymentQueue.default().add(self)
		
		if XUAppSetup.isDebuggingInAppPurchases {
			self.purchasedProductIdentifiers = self.delegate.availableProductIdentifiers
		} else if let savedPurchases = UserDefaults.standard.array(forKey: XUInAppPurchasesDefaultsKey) as? [String] {
			let allowedIdentifiers = self.delegate.availableProductIdentifiers
			for hashedIdentifier in savedPurchases {
				for inAppPurchaseID in allowedIdentifiers {
					let hashedInAppIdentifier = inAppPurchaseID + ProcessInfo.processInfo.processName.md5Digest.md5Digest
					if hashedInAppIdentifier == hashedIdentifier && !self.purchasedProductIdentifiers.contains(inAppPurchaseID) {
						self.purchasedProductIdentifiers.append(inAppPurchaseID)
					}
				}
			}
			
			XULog("Restored in-app purchases: \(purchasedProductIdentifiers)")
		}else{
			XULog("No saved in-app purchases data")
		}
		
		if NSApp == nil {
			#if os(iOS)
				let notificationName = UIApplicationDidFinishLaunchingNotification
			#else
				let notificationName = NSNotification.Name.NSApplicationDidFinishLaunching
			#endif

			NotificationCenter.default.addObserver(self, selector: #selector(XUInAppPurchaseManager._innerInit), name: notificationName, object: nil)
		} else {
			self._innerInit()
		}
		
		#if os(iOS)
			let notificationName = UIApplicationWillTerminateNotification
		#else
			let notificationName = NSNotification.Name.NSApplicationWillTerminate
		#endif
		NotificationCenter.default.addObserver(self, selector: #selector(XUInAppPurchaseManager.save), name: notificationName, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(XUInAppPurchaseManager._removeAsObserver(_:)), name: notificationName, object: nil)
	}
	
	public func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
		XULog("Payment queue got updated with transactions \(transactions)")
		
		for transaction in transactions {
			let purchasedProductIdentifier = transaction.payment.productIdentifier
			
			XULog("\(transaction.payment.productIdentifier), state \(transaction.transactionState)")
			
			switch transaction.transactionState {
				case SKPaymentTransactionState.failed:
					if let error = transaction.error {
						XU_PERFORM_BLOCK_ON_MAIN_THREAD({ () -> Void in
							self.delegate.inAppPurchaseManager(self, failedToPurchaseProductWithIdentifier: purchasedProductIdentifier, error: error)
						})
					}
					SKPaymentQueue.default().finishTransaction(transaction)
					break
				case SKPaymentTransactionState.purchasing:
					// Nothing really to be done, either failed or hasn't been processed yet
					break
				case SKPaymentTransactionState.purchased: fallthrough
				case SKPaymentTransactionState.restored:
					// Add to purchased items
					XULog("Purchased item with identifier \(purchasedProductIdentifier)")
					if !self.purchasedProductIdentifiers.contains(purchasedProductIdentifier) {
						self.purchasedProductIdentifiers.append(purchasedProductIdentifier)
					}
					
					SKPaymentQueue.default().finishTransaction(transaction)
					if transaction.transactionState != SKPaymentTransactionState.restored {
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
		
		XU_PERFORM_BLOCK_ON_MAIN_THREAD {
			NotificationCenter.default.post(name: .purchasesDidChangeNotification, object: self)
		}
	}
	
	
	public func paymentQueue(_ queue: SKPaymentQueue, restoreCompletedTransactionsFailedWithError error: Error) {
		XULog("Restoration failed with an error \(error)")
		
		XU_PERFORM_BLOCK_ON_MAIN_THREAD { () -> Void in
			self.delegate.inAppPurchaseManager(self, failedToRestorePurchasesWithError: error as NSError)
		}
	}
	
	public func paymentQueueRestoreCompletedTransactionsFinished(_ queue: SKPaymentQueue) {
		XULog("Finished restoration.")
		
		XU_PERFORM_BLOCK_ON_MAIN_THREAD { () -> Void in
			self.delegate.inAppPurchaseManagerDidRestorePurchases(self)
		}
	}
	
	public func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
		XU_PERFORM_BLOCK_ON_MAIN_THREAD_ASYNC({
			let products = response.products
			if products.count > 0 {
				XULog("Found new product identifiers \(products)")
				self.productsAvailableForPurchase += products
				self.productsAvailableForPurchase = self.productsAvailableForPurchase.sortedByTitle()
			}
			
			NotificationCenter.default.post(name: .availableProductsDidLoadNotification, object: self)
			
			// Product was not found in the App Store
			let invalidProductIdentifiers = response.invalidProductIdentifiers
			if invalidProductIdentifiers.count > 0 {
				XULog("Invalid product identifiers \(invalidProductIdentifiers)")
			}
			
			self.isLoadingProducts = false
		})
	}
	
	@available(*, deprecated, renamed: "purchase(product:)")
	public func purchaseProduct(_ product: SKProduct) {
		self.purchase(product: product)
	}
	
	/// Starts a purchase. This is asynchronous and the delegate is notified about
	/// the outcome.
	public func purchase(product: SKProduct) {
		let payment = SKPayment(product: product)
		SKPaymentQueue.default().add(payment)
	}
	
	/// Reloads products available for purchase. Usually is done automatically,
	/// but you may re-trigger this e.g. on network failure.
	public func reloadProductsAvailableForPurchase() {
		if isLoadingProducts {
			// Already loading
			return
		}
		
		isLoadingProducts = true
		__XUInAppPurchaseManagerHelper.requestProducts(withIdentifiers: self.delegate.availableProductIdentifiers, with: self)
	}
	
	public func request(_ request: SKRequest, didFailWithError error: Error) {
		XULog("An error getting products occurred: \(error)")
		
		isLoadingProducts = false
		
		XU_PERFORM_BLOCK_ON_MAIN_THREAD {
			self.delegate.inAppPurchaseManager(self, failedToLoadInAppPurchasesWithError: error)
		}
	}
	
	/// Starts restoration of purchases. See delegate methods for callbacks.
	public func restorePurchases() {
		SKPaymentQueue.default().restoreCompletedTransactions()
	}
	
	/// Saves the in-app purchases. Seldomly needed to be called manually.
	public func save() {
		XULog("Saving in app purchases \(self.purchasedProductIdentifiers)")
		
		let hashedIdentifiers = self.purchasedProductIdentifiers.map { (identifier) -> String in
			return identifier + ProcessInfo.processInfo.processName.md5Digest.md5Digest
		}
		
		UserDefaults.standard.set(hashedIdentifiers, forKey: XUInAppPurchasesDefaultsKey)
		UserDefaults.standard.synchronize()
		
		XULog("In app purchases saved successfully")
	}
	
	
}


