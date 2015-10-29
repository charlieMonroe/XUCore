// 
// NSDataAdditions.h
// 
// Created by Charlie Monroe
// 
// Copyright (c) 2010-14 Charlie Monroe Software. All rights reserved.
// 


#import <Foundation/Foundation.h>

/*
 * Allows base64-encoding and decoding compatible with
 * earlier OS's.
 */

@interface NSData (NSDataAdditions)

+(nullable NSData *)dataFromBase64String:(nullable NSString *)aString DEPRECATED_ATTRIBUTE;
+(nullable NSData *)dataWithBase64String:(nullable NSString *)aString DEPRECATED_MSG_ATTRIBUTE("Use -initWithBase64EncodedString:options:");

/** Returns data from a string such as 194736ca92698d0282b76e979f32b1fa7b9b6d. */
+(nonnull instancetype)dataWithHexEncodedString:(nonnull NSString *)hexString;


-(nullable NSString *)base64EncodedString DEPRECATED_MSG_ATTRIBUTE("Use -base64EncodedStringWithOptions:");

-(nonnull NSArray<NSNumber *> *)byteArrayWithZerosIncluded:(BOOL)includeZeros;
-(NSUInteger)indexOfFirstOccurrenceOfBytes:(nonnull const char *)bytes ofLength:(NSUInteger)length;
-(NSUInteger)readIntegerOfLength:(size_t)length startingAtIndex:(NSUInteger)index;

@property (readonly, nonnull, nonatomic) NSString *MD5Digest;

@end

