/*
 *  NSData+CommonCrypto.h
 *  AQToolkit
 *
 *  Created by Jim Dovey on 31/8/2008.
 *
 *  Copyright (c) 2008-2009, Jim Dovey
 *  All rights reserved.
 *  
 *  Redistribution and use in source and binary forms, with or without
 *  modification, are permitted provided that the following conditions
 *  are met:
 *
 *  Redistributions of source code must retain the above copyright notice,
 *  this list of conditions and the following disclaimer.
 *  
 *  Redistributions in binary form must reproduce the above copyright
 *  notice, this list of conditions and the following disclaimer in the
 *  documentation and/or other materials provided with the distribution.
 *  
 *  Neither the name of this project's author nor the names of its
 *  contributors may be used to endorse or promote products derived from
 *  this software without specific prior written permission.
 *
 *  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 *  "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT 
 *  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS 
 *  FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 *  HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 *  SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
 *  TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 *  PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF 
 *  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING 
 *  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS 
 *  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 */

@import Foundation;
#import <CommonCrypto/CommonCryptor.h>
#import <CommonCrypto/CommonHMAC.h>

// Deprecation notice - use pure Swift methods on Data.

extern NSString * const kCommonCryptoErrorDomain;

@interface NSError (CommonCryptoErrorDomain)
+ (NSError *) errorWithCCCryptorStatus: (CCCryptorStatus) status;
@end

@interface NSData (CommonDigest)

- (NSData *) MD2Sum DEPRECATED_ATTRIBUTE;
- (NSData *) MD4Sum DEPRECATED_ATTRIBUTE;
- (NSData *) MD5Sum DEPRECATED_ATTRIBUTE;

- (NSData *) SHA1Hash DEPRECATED_ATTRIBUTE;
- (NSData *) SHA224Hash DEPRECATED_ATTRIBUTE;
- (NSData *) SHA256Hash DEPRECATED_ATTRIBUTE;
- (NSData *) SHA384Hash DEPRECATED_ATTRIBUTE;
- (NSData *) SHA512Hash DEPRECATED_ATTRIBUTE;

@end

@interface NSData (CommonCryptor)

- (NSData *) AES256EncryptedDataUsingKey: (id) key error: (NSError **) error DEPRECATED_ATTRIBUTE;
- (NSData *) decryptedAES256DataUsingKey: (id) key error: (NSError **) error DEPRECATED_ATTRIBUTE;

- (NSData *) DESEncryptedDataUsingKey: (id) key error: (NSError **) error DEPRECATED_ATTRIBUTE;
- (NSData *) decryptedDESDataUsingKey: (id) key error: (NSError **) error DEPRECATED_ATTRIBUTE;

- (NSData *) CASTEncryptedDataUsingKey: (id) key error: (NSError **) error DEPRECATED_ATTRIBUTE;
- (NSData *) decryptedCASTDataUsingKey: (id) key error: (NSError **) error DEPRECATED_ATTRIBUTE;

@end

@interface NSData (LowLevelCommonCryptor)

- (NSData *) dataEncryptedUsingAlgorithm: (CCAlgorithm) algorithm
									 key: (id) key		// data or string
								   error: (CCCryptorStatus *) error DEPRECATED_ATTRIBUTE;
- (NSData *) dataEncryptedUsingAlgorithm: (CCAlgorithm) algorithm
									 key: (id) key		// data or string
                                 options: (CCOptions) options
								   error: (CCCryptorStatus *) error DEPRECATED_ATTRIBUTE;
- (NSData *) dataEncryptedUsingAlgorithm: (CCAlgorithm) algorithm
									 key: (id) key		// data or string
					initializationVector: (id) iv		// data or string
								 options: (CCOptions) options
								   error: (CCCryptorStatus *) error DEPRECATED_ATTRIBUTE;
- (NSData *) dataEncryptedUsingAlgorithm: (CCAlgorithm) algorithm
				     key: (id) key		// data or string
		    initializationVector: (id) iv		// data or string
				    mode:(CCMode)mode
				 padding:(CCPadding)padding
				 options: (CCOptions) options
				   error: (CCCryptorStatus *) error DEPRECATED_ATTRIBUTE;

- (NSData *) decryptedDataUsingAlgorithm: (CCAlgorithm) algorithm
									 key: (id) key		// data or string
								   error: (CCCryptorStatus *) error DEPRECATED_ATTRIBUTE;
- (NSData *) decryptedDataUsingAlgorithm: (CCAlgorithm) algorithm
									 key: (id) key		// data or string
                                 options: (CCOptions) options
								   error: (CCCryptorStatus *) error DEPRECATED_ATTRIBUTE;
- (NSData *) decryptedDataUsingAlgorithm: (CCAlgorithm) algorithm
									 key: (id) key		// data or string
					initializationVector: (id) iv		// data or string
								 options: (CCOptions) options
								   error: (CCCryptorStatus *) error DEPRECATED_ATTRIBUTE;

@end

@interface NSData (CommonHMAC)

- (NSData *) HMACWithAlgorithm: (CCHmacAlgorithm) algorithm DEPRECATED_ATTRIBUTE;
- (NSData *) HMACWithAlgorithm: (CCHmacAlgorithm) algorithm key: (id) key DEPRECATED_ATTRIBUTE;

@end
