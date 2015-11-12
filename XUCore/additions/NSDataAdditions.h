// 
// NSDataAdditions.h
// 
// Created by Charlie Monroe
// 
// Copyright (c) 2010-14 Charlie Monroe Software. All rights reserved.
// 


#import <Foundation/Foundation.h>

@interface NSData (NSDataAdditions)

/** Returns data from a string such as 194736ca92698d0282b76e979f32b1fa7b9b6d. */
+(nonnull instancetype)dataWithHexEncodedString:(nonnull NSString *)hexString;


-(nonnull NSArray<NSNumber *> *)byteArrayWithZerosIncluded:(BOOL)includeZeros;
-(NSUInteger)indexOfFirstOccurrenceOfBytes:(nonnull const char *)bytes ofLength:(NSUInteger)length;
-(NSUInteger)readIntegerOfLength:(size_t)length startingAtIndex:(NSUInteger)index;

@property (readonly, nonnull, nonatomic) NSString *MD5Digest;

@end

