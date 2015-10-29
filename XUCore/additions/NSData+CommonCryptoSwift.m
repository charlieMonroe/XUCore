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

-(NSData *)decryptedRC4DataWithEncryptionKey:(NSString *)key {
	CCCryptorStatus status;
	NSData *decryptedData = [self decryptedDataUsingAlgorithm:kCCAlgorithmRC4 key:key error:&status];
	return decryptedData;
}


@end
