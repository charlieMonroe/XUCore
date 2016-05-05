//
//  NSData+CommonCryptoSwift.m
//  DownieCore
//
//  Created by Charlie Monroe on 10/26/15.
//  Copyright © 2015 Charlie Monroe Software. All rights reserved.
//

#import "NSData+CommonCryptoSwift.h"

#import "NSData+CommonCrypto.h"

@implementation NSData (CommonCryptoSwift)

+(NSString *)MD5DigestOfBytes:(const void *)bytes ofLength:(NSInteger)length {
	unsigned char result[16];
	CC_MD5(bytes, (CC_LONG)length, result);
	
	return [NSString stringWithFormat:@"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
			result[0], result[1], result[2], result[3],
			result[4], result[5], result[6], result[7],
			result[8], result[9], result[10], result[11],
			result[12], result[13], result[14], result[15]
		];
}

-(NSData *)decryptedRC4DataWithEncryptionKey:(NSString *)key {
	CCCryptorStatus status;
	NSData *decryptedData = [self decryptedDataUsingAlgorithm:kCCAlgorithmRC4 key:key error:&status];
	return decryptedData;
}

-(NSData *)HMACSHA1WithKey:(NSString *)key {
	return [self HMACWithAlgorithm:kCCHmacAlgSHA1 key:key];
}

@end
