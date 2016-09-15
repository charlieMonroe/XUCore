//
//  NSData+CommonCryptoSwift.h
//  DownieCore
//
//  Created by Charlie Monroe on 10/26/15.
//  Copyright © 2015 Charlie Monroe Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSData (CommonCryptoSwift)

/// Digests bytes.
+(nonnull NSString *)MD5DigestOfBytes:(nonnull const void *)bytes ofLength:(NSInteger)length;

/// Digests bytes.
+(nonnull NSString *)SHA512DigestOfBytes:(nonnull const void *)bytes ofLength:(NSInteger)length;


/// Decrypts data with RC4 using an encryption key
-(nullable NSData *)decryptedRC4DataWithEncryptionKey:(nonnull NSString *)key;

/// Creates a HMAC-SH1 with custom key.
-(nullable NSData *)HMACSHA1WithKey:(nonnull NSString *)key;

/// Digest.
-(nonnull NSData *)SHA512Digest;

@end
