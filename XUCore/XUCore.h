//
//  XUCore.h
//  XUCore
//
//  Created by Charlie Monroe on 10/1/15.
//  Copyright © 2015 Charlie Monroe Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>

//! Project version number for XUCore.
FOUNDATION_EXPORT double XUCoreVersionNumber;

//! Project version string for XUCore.
FOUNDATION_EXPORT const unsigned char XUCoreVersionString[];

/** Additions. */
#import "NSAlertAdditions.h"
#import "NSArrayAdditions.h"
#import "NSAttributedStringAdditions.h"
#import "NSBezierPathAdditions.h"
#import "NSBundleAdditions.h"
#import "NSButtonAdditions.h"
#import "NSButtonCellAdditions.h"
#import "NSColorAdditions.h"
#import "NSData+CommonCryptoSwift.h"
#import "NSDataAdditions.h"
#import "NSDateAdditions.h"
#import "NSDecimalNumberAdditions.h"
#import "NSDictionaryAdditions.h"
#import "NSEventAdditions.h"
#import "NSHTTPURLResponse.h"
#import "NSImageAdditions.h"
#import "NSLockAdditions.h"
#import "NSMutableDictionaryAdditions.h"
#import "NSMutableURLRequestAdditions.h"
#import "NSNotificationAdditions.h"
#import "NSOpenPanelAdditions.h"
#import "NSRecursiveLockAdditions.h"
#import "NSShadowAdditions.h"
#import "NSStringAdditions.h"
#import "NSStringGeometrics.h"
#import "NSTableColumnAdditions.h"
#import "NSTabViewAdditions.h"
#import "NSTextFieldAdditions.h"
#import "NSTimerAdditions.h"
#import "NSToolbarAdditions.h"
#import "NSURL+NSURLAdditions.h"
#import "NSURLConnectionAdditions.h"
#import "NSUserDefaultsAdditions.h"
#import "NSViewAdditions.h"
#import "NSWindow-NoodleEffects.h"
#import "NSXMLAdditions.h"

/** AppStore. */
#import "FCAppStoreHidingView.h"
#import "FCAppStoreMenuCleaner.h"
#import "FCInAppPurchaseManager.h"

/** Core. */
#import "FCApplication.h"
#import "FCAppScopeBookmarksManager.h"
#import "FCKeychain.h"
#import "FCSubclassCollector.h"
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
#import "FCRedView.h"

/** Documents. */
#import "FCCSVDocument.h"

/** Localization. */
#import "FCLocalizationSupport.h"
#import "NSMenuLocalizationSupport.h"
#import "NSViewLocalizationSupport.h"
#import "NSWindowLocalizationSupport.h"

/** Misc. */
#import "FCHardwareInfo.h"
#import "FCMouseTracker.h"
#import "FCRandomGenerator.h"
#import "FCTimeUtilities.h"
#import "FCUniqueStringManager.h"

/** Network. */
#import "FCCURLConnection.h"
#import "FCURLHandlingCenter.h"

/** Regex. */
#import "XURegex.h"

/** Transformers. */
#import "FCArrayNotEmpty.h"
#import "FCAttributedStringTransformer.h"
#import "FCFileSizeTransformer.h"
#import "FCTrimmingTransformer.h"
#import "FCZeroBasedIndexTransformer.h"

