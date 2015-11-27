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
#import "NSArrayAdditions.h"
#import "NSBezierPathAdditions.h"
#import "NSData+CommonCryptoSwift.h"
#import "NSDataAdditions.h"
#import "NSDictionaryAdditions.h"
#import "NSStringAdditions.h"
#import "NSStringGeometrics.h"
#import "NSXMLAdditions.h"

/** Core. */
#import "FCKeychain.h" // Deprecated
#import "XUAbstract.h"
#import "XUBlockThreading.h"
#import "XUExceptionHandler.h"

/** Data - all deprectated. */
#import "FCContextHolder.h"
#import "FCDataEntity.h"
#import "FCPersistentDataStorage.h"
#import "FCTemporaryDataStorage.h"

/** Debug. */
#import "FCLog.h" // Deprecated

/** Documents. */
#import "FCCSVDocument.h"

/** Localization. */
#import "FCLocalizationSupport.h" // Deprecated

/** Regex. */
#import "XURegex.h"
