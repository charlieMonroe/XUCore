//
//  XUCoreMobile.h
//  XUCoreMobile
//
//  Created by Charlie Monroe on 10/1/15.
//  Copyright © 2015 Charlie Monroe Software. All rights reserved.
//

#import <UIKit/UIKit.h>

//! Project version number for XUCoreMobile.
FOUNDATION_EXPORT double XUCoreMobileVersionNumber;

//! Project version string for XUCoreMobile.
FOUNDATION_EXPORT const unsigned char XUCoreMobileVersionString[];

/** Additions. */
#import "NSArrayAdditions.h"
#import "NSAttributedStringAdditions.h"
#import "NSBundleAdditions.h"
#import "NSData+CommonCryptoSwift.h"
#import "NSDataAdditions.h"
#import "NSDateAdditions.h"
#import "NSDecimalNumberAdditions.h"
#import "NSDictionaryAdditions.h"
#import "NSHTTPURLResponse.h"
#import "NSImageAdditions.h"
#import "NSLockAdditions.h"
#import "NSMutableDictionaryAdditions.h"
#import "NSMutableURLRequestAdditions.h"
#import "NSNotificationAdditions.h"
#import "NSRecursiveLockAdditions.h"
#import "NSStringAdditions.h"
#import "NSTimerAdditions.h"
#import "NSURL+NSURLAdditions.h"
#import "NSURLConnectionAdditions.h"
#import "NSUserDefaultsAdditions.h"
#import "UIAlertViewAdditions.h"
#import "UIView+Enclosing.h"

/** AppStore. */
#import "FCInAppPurchaseManager.h"

/** Core. */
#import "FCAppScopeBookmarksManager.h"
#import "FCKeychain.h"
#import "FCSubclassCollector.h"
#import "iOSCommon.h"
#import "XUAbstract.h"
#import "XUBlockThreading.h"
#import "XUPowerAssertion.h"
#import "XUString.h"

/** Data. */
#import "FCContextHolder.h"
#import "FCDataEntity.h"
#import "FCPersistentDataStorage.h"
#import "FCTemporaryDataStorage.h"

/** Debug. */
#import "FCLog.h"

/** Documents. */
#import "FCCSVDocument.h"

/** Localization. */
#import "FCLocalizationSupport.h"
#import "NSViewLocalizationSupport.h"

/** Misc. */
#import "FCRandomGenerator.h"
#import "FCTimeUtilities.h"
#import "FCUniqueStringManager.h"

/** Regex. */
#import "XURegex.h"

/** Transformers. */
#import "FCArrayNotEmpty.h"
#import "FCAttributedStringTransformer.h"
#import "FCFileSizeTransformer.h"
#import "FCTrimmingTransformer.h"
#import "FCZeroBasedIndexTransformer.h"
