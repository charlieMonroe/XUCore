//
//  NSXMLAdditions.h
//  DownieCore
//
//  Created by Charlie Monroe on 5/10/14.
//  Copyright (c) 2014 Charlie Monroe Software. All rights reserved.
//

@import Foundation;

#if TARGET_OS_IPHONE
	#import "NSXML.h"
#endif

@interface NSXMLNode (XUAdditions)

/** This is a convenience method for Swift 2.0, where instead of returning error,
 * it throws it, adding completely unnecessary do-catch blocks.
 */
-(nonnull NSArray<NSXMLNode *> *)nodesForXPath:(nonnull NSString *)xpath;

@end

@interface NSDictionary (XMLAdditions)

/** This creates a NSXMLElement instance from the contents of the dictionary.
 * This assumes that the dictionary only contains plist-friendly content.
 *
 * Requires keys to be strings.
 *
 * All arrays require to consist of dictionaries.
 */
-(nonnull NSXMLElement *)XMLElementWithName:(nonnull NSString *)elementName;

@end


