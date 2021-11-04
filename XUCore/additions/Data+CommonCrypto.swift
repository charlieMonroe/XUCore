//
//  Data+CommonCrypto.swift
//  XUCore
//
//  Created by Charlie Monroe on 10/6/21.
//  Copyright © 2021 Charlie Monroe Software. All rights reserved.
//

import CommonCrypto
import Foundation

extension Data {
	
	public struct Crypto {
		
		/// Key value - it can be either a string or data.
		public enum KeyValue {
			case string(String)
			case data(Data)
			
			/// Returns data of the key.
			public var dataValue: Data {
				switch self {
				case .data(let data):
					return data
				case .string(let string):
					return string.utf8Data
				}
			}
		}
		
	}

	private func _fixKeyLengths(for algorithm: CCAlgorithm, key: inout Data, initialVector: inout Data?) {
		let targetLength: Int
		switch algorithm {
		case CCAlgorithm(kCCAlgorithmAES128):
			if key.count <= 16 {
				targetLength = 16
			} else if key.count <= 24 {
				targetLength = 24
			} else {
				targetLength = 32
			}
		case CCAlgorithm(kCCAlgorithmRC4):
			targetLength = key.count > 512 ? 512 : key.count
		default:
			return
		}
		
		if key.count != targetLength {
			if key.count < targetLength {
				// Append zeros.
				key.append(contentsOf: Array<UInt8>(repeating: 0, count: targetLength - key.count))
			} else {
				// Trim.
				key = key.prefix(targetLength)
			}
		}
		
		if var iv = initialVector, iv.count != targetLength {
			if iv.count < targetLength {
				// Append zeros.
				iv.append(contentsOf: Array<UInt8>(repeating: 0, count: targetLength - iv.count))
			} else {
				// Trim.
				iv = iv.prefix(targetLength)
			}
			initialVector = iv
		}
	}
	
	private func _hashWith(length: Int32, function: (UnsafeRawPointer?, CC_LONG, UnsafeMutablePointer<UInt8>?) -> UnsafeMutablePointer<UInt8>?) -> Data {
		return self.withUnsafeBytes({ (ptr: UnsafeRawBufferPointer) in
			var result = Array<UInt8>(repeating: 0, count: Int(length))
			_ = result.withUnsafeMutableBufferPointer { resultPointer in
				function(ptr.baseAddress, UInt32(self.count), resultPointer.baseAddress)
			}

			return Data(result)
		})
	}
	
	public func decryptedAES128Data(with key: Crypto.KeyValue, initialVector: Crypto.KeyValue? = nil) -> Data? {
		return self.decryptedData(using: CCAlgorithm(kCCAlgorithmAES128), key: key, initialVector: initialVector?.dataValue)
	}
	
	public func decryptedAES256Data(with key: Crypto.KeyValue, initialVector: Crypto.KeyValue? = nil) -> Data? {
		return self.decryptedData(using: CCAlgorithm(kCCAlgorithmAES), key: key, initialVector: initialVector?.dataValue)
	}
	
	/// Returns data decrypted using algorithm and key.
	public func decryptedData(using algorithm: CCAlgorithm, key: Crypto.KeyValue, initialVector: Data? = nil) -> Data? {
		var status: CCCryptorStatus = CCCryptorStatus(kCCSuccess)
		
		var keyData = key.dataValue
		var ivData = initialVector
		self._fixKeyLengths(for: algorithm, key: &keyData, initialVector: &ivData)
		
		var cryptor: CCCryptorRef!
		return self.withUnsafeBytes	{ dataPtr -> Data? in
			keyData.withUnsafeBytes { keyPtr -> Data? in
				(ivData ?? Data()).withUnsafeBytes { ivPtr -> Data? in
					status = CCCryptorCreate(CCOperation(kCCDecrypt), algorithm, 0, keyPtr.baseAddress, keyData.count, initialVector == nil ? nil : ivPtr.baseAddress, &cryptor)
					
					guard status == CCCryptorStatus(kCCSuccess), cryptor != nil else {
						return nil
					}
					
					let bufferSize = CCCryptorGetOutputLength(cryptor, self.count, true)
					guard bufferSize != 0, let buffer = malloc(bufferSize) else {
						return nil
					}
					
					var bufferUsed = 0
					var bytesTotal = 0
					
					status = CCCryptorUpdate(cryptor, dataPtr.baseAddress, self.count, buffer, bufferSize, &bufferUsed)
					guard status == CCCryptorStatus(kCCSuccess) else {
						free(buffer)
						return nil
					}
					
					bytesTotal += bufferUsed
					status = CCCryptorFinal(cryptor, buffer.advanced(by: bufferUsed), bufferSize - bufferUsed, &bufferUsed)
					guard status == CCCryptorStatus(kCCSuccess) else {
						free(buffer)
						return nil
					}
					
					bytesTotal += bufferUsed
					return Data(bytesNoCopy: buffer, count: bytesTotal, deallocator: .free)
				}
			}
		}
	}
	
	/// Returns data encrypted using algorithm and key.
	public func encryptedData(using algorithm: CCAlgorithm, key: Crypto.KeyValue, initialVector: Data? = nil) -> Data? {
		var status: CCCryptorStatus = CCCryptorStatus(kCCSuccess)
		
		var keyData = key.dataValue
		var ivData = initialVector
		self._fixKeyLengths(for: algorithm, key: &keyData, initialVector: &ivData)
		
		var cryptor: CCCryptorRef!
		return self.withUnsafeBytes	{ dataPtr -> Data? in
			keyData.withUnsafeBytes { keyPtr -> Data? in
				(ivData ?? Data()).withUnsafeBytes { ivPtr -> Data? in
					status = CCCryptorCreate(CCOperation(kCCEncrypt), algorithm, 0, keyPtr.baseAddress, keyData.count, initialVector == nil ? nil : ivPtr.baseAddress, &cryptor)
					
					guard status == CCCryptorStatus(kCCSuccess), cryptor != nil else {
						return nil
					}
					
					let bufferSize = CCCryptorGetOutputLength(cryptor, self.count, true)
					guard bufferSize != 0, let buffer = malloc(bufferSize) else {
						return nil
					}
					
					var bufferUsed = 0
					var bytesTotal = 0
					
					status = CCCryptorUpdate(cryptor, dataPtr.baseAddress, self.count, buffer, bufferSize, &bufferUsed)
					guard status == CCCryptorStatus(kCCSuccess) else {
						free(buffer)
						return nil
					}
					
					bytesTotal += bufferUsed
					status = CCCryptorFinal(cryptor, buffer.advanced(by: bufferUsed), bufferSize - bufferUsed, &bufferUsed)
					guard status == CCCryptorStatus(kCCSuccess) else {
						free(buffer)
						return nil
					}
					
					bytesTotal += bufferUsed
					return Data(bytesNoCopy: buffer, count: bytesTotal, deallocator: .free)
				}
			}
		}
	}
	
	/// Decrypts data with RC4 using an encryption key.
	public func decryptedRC4Data(with key: Crypto.KeyValue) -> Data? {
		return self.decryptedData(using: CCAlgorithm(kCCAlgorithmRC4), key: key)
	}
	
	/// Encrypts data with RC4 using an encryption key.
	public func encryptedRC4Data(with key: Crypto.KeyValue) -> Data? {
		return self.encryptedData(using: CCAlgorithm(kCCAlgorithmRC4), key: key, initialVector: nil)
	}
	
	
	private func _hmacHash(with key: Data, algorithm: CCHmacAlgorithm, length: Int32) -> Data {
		return self.withUnsafeBytes({ dataPtr in
			var result = Array<UInt8>(repeating: 0, count: Int(length))
			
			key.withUnsafeBytes { keyPtr in
				result.withUnsafeMutableBufferPointer { resultPointer in
					CCHmac(algorithm, keyPtr.baseAddress, key.count, dataPtr.baseAddress, self.count, resultPointer.baseAddress)
				}
			}
			
			return Data(result)
		})
	}
	
	
	/// Creates a HMAC-SHA1 with custom key.
	public func hmacSHA1(with key: Crypto.KeyValue) -> Data {
		return self._hmacHash(with: key.dataValue, algorithm: CCHmacAlgorithm(kCCHmacAlgSHA1), length: CC_SHA1_DIGEST_LENGTH)
	}
	
	/// Creates a HMAC-SHA265 with custom key.
	public func hmacSHA265(with key: Crypto.KeyValue) -> Data {
		return self._hmacHash(with: key.dataValue, algorithm: CCHmacAlgorithm(kCCHmacAlgSHA256), length: CC_SHA256_DIGEST_LENGTH)
	}
		
	/// Returns MD5 digest of data.
	public var md5Digest: Data {
		return self._hashWith(length: CC_MD5_DIGEST_LENGTH, function: CC_MD5)
	}
	
	/// SHA-1 digest.
	public var sha1Digest: Data {
		return self._hashWith(length: CC_SHA1_DIGEST_LENGTH, function: CC_SHA1)
	}
	
	/// SHA-256 digest.
	public var sha256Digest: Data {
		return self._hashWith(length: CC_SHA256_DIGEST_LENGTH, function: CC_SHA256)
	}
	
	/// SHA-512 digest.
	public var sha512Digest: Data {
		return self._hashWith(length: CC_SHA512_DIGEST_LENGTH, function: CC_SHA512)
	}
	
}
