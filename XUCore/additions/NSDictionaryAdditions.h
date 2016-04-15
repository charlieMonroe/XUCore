// 
// NSDictionaryAdditions.h
// 
// Created by Charlie Monroe
// 
// Copyright (c) 2010-16 Charlie Monroe Software. All rights reserved.
// 


#import <Foundation/Foundation.h>

@interface NSDictionary (NSDictionaryAdditions)

+(nullable instancetype)dictionaryWithContentsOfData:(nonnull NSData *)data;

-(BOOL)containsString:(nonnull NSString *)string NS_SWIFT_UNAVAILABLE("Use native Swift Dictionary.");

-(nonnull instancetype)dictionaryRepresentation NS_SWIFT_UNAVAILABLE("Use native Swift Dictionary.");

-(nullable id)firstNonNilObjectForKeys:(nonnull NSArray *)keys NS_SWIFT_UNAVAILABLE("Use native Swift Dictionary.");

-(nullable NSString *)searchForString:(nonnull NSString *)string NS_SWIFT_UNAVAILABLE("Use native Swift Dictionary.");

/** This will put together all key-value pairs as key1=value1&key2=value2&...,
 * percent encoding the value. If the value is not of NSString class - description
 * is called on that object.
 */
-(nonnull NSString *)URLQueryString NS_SWIFT_UNAVAILABLE("Use native Swift Dictionary.");

@end

