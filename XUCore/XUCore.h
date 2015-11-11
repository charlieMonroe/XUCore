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
#import "NSBezierPathAdditions.h"
#import "NSColorAdditions.h"
#import "NSData+CommonCryptoSwift.h"
#import "NSDataAdditions.h"
#import "NSDictionaryAdditions.h"
#import "NSImageAdditions.h"
#import "NSMutableDictionaryAdditions.h"
#import "NSRecursiveLockAdditions.h"
#import "NSStringAdditions.h"
#import "NSStringGeometrics.h"
#import "NSTimerAdditions.h"
#import "NSURLConnectionAdditions.h"
#import "NSWindow-NoodleEffects.h"
#import "NSXMLAdditions.h"

/** AppStore. */
#import "FCAppStoreHidingView.h"
#import "FCAppStoreMenuCleaner.h"
#import "FCInAppPurchaseManager.h"

/** Core. */
#import "FCAppScopeBookmarksManager.h"
#import "FCKeychain.h"
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

/** Misc. */
#import "FCMouseTracker.h"

/** Regex. */
#import "XURegex.h"
