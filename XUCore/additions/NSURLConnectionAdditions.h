// 
// NSURLConnectionAdditions.h
// 
// Created by Charlie Monroe
// 
// Copyright (c) 2010-13 Fuel Collective, LLC. All rights reserved.
// 


#import <Foundation/Foundation.h>

@interface NSURLConnection (NSURLConnectionAdditions)

+(long long)getLenghtOfRequest:(nonnull NSURLRequest *)request returningResponse:(NSURLResponse * __nullable * __nullable)response DEPRECATED_ATTRIBUTE;
+(nullable NSData *)sendSynchronousRequest:(nonnull NSURLRequest *)request asUserAgent:(nullable NSString *)userAgent returningResponse:(NSURLResponse * __nullable * __nullable)response error:(NSError * __nullable * __nullable)error DEPRECATED_ATTRIBUTE;
+(nullable NSData *)sendSynchronousRequest:(nonnull NSURLRequest *)request asUserAgent:(nullable NSString *)userAgent DEPRECATED_ATTRIBUTE;
+(nullable NSData *)sendAuthenticatedSynchronousRequest:(nonnull NSURLRequest *)request returningResponse:(NSURLResponse * __nullable * __nullable)response error:(NSError * __nullable * __nullable)error DEPRECATED_ATTRIBUTE;

@end

