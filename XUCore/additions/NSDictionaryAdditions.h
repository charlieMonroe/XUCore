// 
// NSDictionaryAdditions.h
// 
// Created by Charlie Monroe
// 
// Copyright (c) 2010-13 Fuel Collective, LLC. All rights reserved.
// 


#import <Foundation/Foundation.h>

@interface NSDictionary (NSDictionaryAdditions)

+(nullable instancetype)dictionaryWithContentsOfData:(nonnull NSData *)data;

-(BOOL)containsString:(nonnull NSString *)string;

-(nonnull instancetype)dictionaryRepresentation;

-(nullable id)firstNonNilObjectForKeys:(nonnull NSArray *)keys;

-(nullable NSString *)searchForString:(nonnull NSString *)string;

/** This will put together all key-value pairs as key1=value1&key2=value2&...,
 * percent encoding the value. If the value is not of NSString class - description
 * is called on that object.
 */
-(nonnull NSString *)URLQueryString;

@end

