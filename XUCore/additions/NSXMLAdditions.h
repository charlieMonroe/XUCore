//
//  NSXMLAdditions.h
//  DownieCore
//
//  Created by Charlie Monroe on 5/10/14.
//  Copyright (c) 2014 Charlie Monroe Software. All rights reserved.
//

#import <Foundation/Foundation.h>

#if TARGET_OS_IPHONE
	#import "NSXML.h"
#endif

@interface NSXMLNode (XUAdditions)

/** This is a convenience method for Swift 2.0, where instead of returning error,
 * it throws it, adding completely unnecessary do-catch blocks.
 */
-(nonnull NSArray<NSXMLNode *> *)nodesForXPath:(nonnull NSString *)xpath;

-(NSInteger)integerValue;
-(nullable NSXMLNode *)firstNodeOnXPath:(nonnull NSString *)xpath;
-(NSInteger)integerValueOfFirstNodeOnXPath:(nonnull NSString *)xpath;
-(NSInteger)integerValueOfFirstNodeOnXPaths:(nonnull NSArray<NSString *> *)xpaths;
-(nullable NSXMLNode *)lastNodeOnXPath:(nonnull NSString *)xpath;
-(nullable NSString *)stringValueOfFirstNodeOnXPath:(nonnull NSString *)xpath;
-(nullable NSString *)stringValueOfFirstNodeOnXPaths:(nonnull NSArray<NSString *> *)xpaths;
-(nullable NSString *)stringValueOfLastNodeOnXPath:(nonnull NSString *)xpath;

/** Will return NULL or nil, if the node isn't NSXMLElement. */
-(NSInteger)integerValueOfAttributeNamed:(nonnull NSString *)attributeName;
-(nullable NSString *)stringValueOfAttributeNamed:(nonnull NSString *)attributeName;

@end

@interface NSXMLElement (XUAdditions)

-(NSInteger)integerValueOfAttributeNamed:(nonnull NSString *)attributeName;
-(nullable NSString *)stringValueOfAttributeNamed:(nonnull NSString *)attributeName;

@end

@interface NSXMLDocument (XUAdditions)

/** This is a convenience method for Swift 2.0, where instead of returning error,
 * it throws it, adding completely unnecessary do-catch blocks.
 */
-(nullable instancetype)initWithXMLString:(nonnull NSString *)string andOptions:(NSInteger)mask;

@end

