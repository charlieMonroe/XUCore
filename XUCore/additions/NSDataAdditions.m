// 
// NSDataAdditions.m
// 
// Created by Charlie Monroe
// 
// Copyright (c) 2010-14 Charlie Monroe Software. All rights reserved.
// 


#import "NSDataAdditions.h"

#import <CommonCrypto/CommonCrypto.h>

@implementation NSData (NSDataAdditions)

+(char)_hexValueOfChar:(unichar)c{
	char result = 0;
	if (c >= '0' && c <= '9'){
		result *= 16;
		result += (c - '0');
	}else if (c >= 'a' && c <= 'f'){
		result *= 16;
		result += (c - 'a') + 10;
	}else if (c >= 'A' && c <= 'F'){
		result *= 16;
		result += (c - 'A') + 10;
	}else{
		return 0;
	}
	return result;
}

+(instancetype)dataWithHexEncodedString:(NSString *)hexString{
	if ([hexString length] % 2 != 0){
		return [NSData data];
	}
	
	NSMutableData *data = [NSMutableData data];
	for (NSUInteger i = 0; i < [hexString length]; i += 2){
		char byte = ([self _hexValueOfChar:[hexString characterAtIndex:i]] << 4) | [self _hexValueOfChar:[hexString characterAtIndex:i + 1]];
		[data appendBytes:&byte length:1];
	}
	return data;

}


-(NSMutableArray*)byteArrayWithZerosIncluded:(BOOL)includeZeros{
	NSMutableArray *result = [NSMutableArray arrayWithCapacity:[self length]];
	for (NSUInteger i = 0; i < [self length]; ++i){
		char c = ((const char*)[self bytes])[i];
		if (c == 0 && !includeZeros){
			continue;
		}
		[result addObject:@(c)];
	}
	return result;
}
-(NSUInteger)indexOfFirstOccurrenceOfBytes:(const char *)bytes ofLength:(NSUInteger)length{
	return [self rangeOfData:[NSData dataWithBytesNoCopy:(void *)bytes length:length freeWhenDone:NO] options:0 range:NSMakeRange(0, [self length])].location;
}
-(NSString *)MD5Digest{
	unsigned char result[16];
	CC_MD5([self bytes], (CC_LONG)[self length], result);
	
	return [NSString stringWithFormat:@"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
			result[0], result[1], result[2], result[3],
			result[4], result[5], result[6], result[7],
			result[8], result[9], result[10], result[11],
			result[12], result[13], result[14], result[15]
		];
}
-(NSUInteger)readIntegerOfLength:(size_t)length startingAtIndex:(NSUInteger)index{
	NSAssert(length <= sizeof(NSUInteger), @"This is a way too big of an int!");
	char buffer[sizeof(NSUInteger)] = { 0 };
	for (NSUInteger i = 0; i < length; ++i){
		char c = (((const char*)[self bytes])[index + i]);
		buffer[length - i - 1] = c;
	}
	return *(NSUInteger*)buffer;
}

@end

