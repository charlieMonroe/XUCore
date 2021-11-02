//
//  NSData+CommonCryptoSwift.h
//  DownieCore
//
//  Created by Charlie Monroe on 10/26/15.
//  Copyright © 2015 Charlie Monroe Software. All rights reserved.
//

@import Foundation;

// Deprecation notice - use pure Swift methods on Data.

@interface NSData (CommonCryptoSwift)

/// Digests bytes.
+(nonnull NSString *)MD5DigestOfBytes:(nonnull const void *)bytes ofLength:(NSInteger)length DEPRECATED_ATTRIBUTE;


/// Decrypts data with RC4 using an encryption key.
-(nullable NSData *)decryptedRC4DataWithEncryptionKey:(nonnull NSString *)key DEPRECATED_ATTRIBUTE;

/// Decrypts data with AES-128 using an encryption key and IV.
-(nullable NSData *)decryptedAES128DataWithEncryptionKey:(nonnull NSString *)key andInitialVector:(nonnull NSString *)vector DEPRECATED_ATTRIBUTE;

/// Decrypts data with AES-128 using an encryption key and IV.
-(nullable NSData *)decryptedAES128DataWithEncryptionDataKey:(nonnull NSData *)key andInitialDataVector:(nonnull NSData *)vector DEPRECATED_ATTRIBUTE;


/// Decrypts data with AES-256 using an encryption key and IV.
-(nullable NSData *)decryptedAES256DataWithEncryptionKey:(nonnull NSString *)key andInitialVector:(nonnull NSString *)vector DEPRECATED_ATTRIBUTE;

/// Decrypts data with AES-256 using an encryption key and IV.
-(nullable NSData *)decryptedAES256DataWithEncryptionDataKey:(nonnull NSData *)key andInitialDataVector:(nonnull NSData *)vector DEPRECATED_ATTRIBUTE;

/// Encrypts data with RC4 using an encryption key.
-(nullable NSData *)encryptedRC4DataWithEncryptionKey:(nonnull NSString *)key DEPRECATED_ATTRIBUTE;

/// Creates a HMAC-SHA1 with custom key.
-(nullable NSData *)HMACSHA1WithKey:(nonnull NSString *)key DEPRECATED_ATTRIBUTE;

/// Creates a HMAC-SHA256 with custom key.
-(nullable NSData *)HMACSHA256WithKey:(nonnull id)key DEPRECATED_ATTRIBUTE;

/// Digest.
-(nonnull NSData *)SHA256Digest DEPRECATED_ATTRIBUTE;

/// Digest.
-(nonnull NSData *)SHA512Digest DEPRECATED_ATTRIBUTE;

/// Digest.
-(nonnull NSData *)SHA1Digest DEPRECATED_ATTRIBUTE;

@end
