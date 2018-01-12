//
//  NSData+CommonCryptoSwift.m
//  DownieCore
//
//  Created by Charlie Monroe on 10/26/15.
//  Copyright © 2015 Charlie Monroe Software. All rights reserved.
//

#import "NSData+CommonCryptoSwift.h"

#import "NSData+CommonCrypto.h"

#import <CommonCrypto/CommonDigest.h>
#import <CommonCrypto/CommonCryptor.h>
#import <CommonCrypto/CommonHMAC.h>


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

-(NSData *)decryptedAES128DataWithEncryptionKey:(NSString *)key andInitialVector:(NSString *)vector {
	return [self decryptedDataUsingAlgorithm:kCCAlgorithmAES128 key:key initializationVector:vector options:0 error:NULL];
}

-(NSData *)decryptedAES128DataWithEncryptionDataKey:(NSData *)key andInitialDataVector:(NSData *)vector {
	return [self decryptedDataUsingAlgorithm:kCCAlgorithmAES128 key:key initializationVector:vector options:0 error:NULL];
}

-(NSData *)decryptedAES256DataWithEncryptionKey:(NSString *)key andInitialVector:(NSString *)vector {
	return [self decryptedDataUsingAlgorithm:kCCAlgorithmAES key:key initializationVector:vector options:0 error:NULL];
}

-(NSData *)decryptedAES256DataWithEncryptionDataKey:(NSData *)key andInitialDataVector:(NSData *)vector {
	return [self decryptedDataUsingAlgorithm:kCCAlgorithmAES key:key initializationVector:vector options:0 error:NULL];
}

-(NSData *)decryptedRC4DataWithEncryptionKey:(NSString *)key {
	CCCryptorStatus status;
	NSData *decryptedData = [self decryptedDataUsingAlgorithm:kCCAlgorithmRC4 key:key error:&status];
	return decryptedData;
}

-(NSData *)encryptedRC4DataWithEncryptionKey:(NSString *)key {
	CCCryptorStatus status;
	NSData *encryptedData = [self dataEncryptedUsingAlgorithm:kCCAlgorithmRC4 key:key error:&status];
	return encryptedData;
}

-(NSData *)HMACSHA1WithKey:(NSString *)key {
	return [self HMACWithAlgorithm:kCCHmacAlgSHA1 key:key];
}

-(NSData *)HMACSHA256WithKey:(id)key {
	NSData * keyData;
	if ([key isKindOfClass:[NSData class]]) {
		keyData = key;
	} else {
		// String
		keyData = [key dataUsingEncoding: NSUTF8StringEncoding];
	}
	
	// this could be either CC_SHA1_DIGEST_LENGTH or CC_MD5_DIGEST_LENGTH. SHA1 is larger.
	unsigned char buf[CC_SHA256_DIGEST_LENGTH];
	CCHmac(kCCHmacAlgSHA256, [keyData bytes], [keyData length], [self bytes], [self length], buf);
	
	return ( [NSData dataWithBytes: buf length: CC_SHA256_DIGEST_LENGTH] );
}

-(NSData *)SHA256Digest {
	return [self SHA256Hash];
}

-(NSData *)SHA512Digest {
	return [self SHA512Hash];
}

-(NSData *)SHA1Digest {
	return [self SHA1Hash];
}

@end
