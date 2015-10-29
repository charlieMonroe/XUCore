//
//  NSData+CommonCryptoSwift.h
//  DownieCore
//
//  Created by Charlie Monroe on 10/26/15.
//  Copyright © 2015 Charlie Monroe Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSData (CommonCryptoSwift)

/// Decrypts data with RC4 using an encryption key
-(nullable NSData *)decryptedRC4DataWithEncryptionKey:(nonnull NSString *)key;

@end
