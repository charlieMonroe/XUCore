//
//  XUString.m
//  DownieCore
//
//  Created by Charlie Monroe on 5/14/15.
//  Copyright (c) 2015 Charlie Monroe Software. All rights reserved.
//

#import "XUString.h"

#import <CommonCrypto/CommonCrypto.h>

#define XUStringMaxLen 65536

@implementation XUString {
	unsigned char _buffer[XUStringMaxLen];
	unsigned _length;
}

+(instancetype)string{
	return [self stringWithString:@""];
}
+(nonnull instancetype)stringFilledWithASCIITableOfLength:(NSUInteger)length{
	XUString *string = [self string];
	for (NSUInteger i = 0; i < length; ++i){
		string->_buffer[i] = (char)i;
	}
	
	string->_length = (unsigned)length;
	return string;
}
+(nonnull instancetype)stringFilledWithChar:(char)c ofLength:(NSUInteger)length{
	XUString *string = [self string];
	for (NSUInteger i = 0; i < length; ++i){
		string->_buffer[i] = c;
	}
	
	string->_length = (unsigned)length;
	return string;
}
+(nonnull instancetype)stringWithDataBytes:(nonnull NSData *)data{
	return [[self alloc] initWithChars:(const char *)[data bytes] ofLength:[data length]];
}
+(instancetype)stringWithString:(NSString *)string{
	return [[self alloc] initWithString:string];
}

-(void)appendChar:(unsigned char)c{
	_buffer[_length] = c;
	++_length;
}
-(unsigned char)characterAtIndex:(NSUInteger)index{
	return _buffer[index];
}
-(id)copy{
	XUString *copy = [[XUString alloc] initWithChars:(const char *)_buffer ofLength:_length];
	return copy;
}
-(id)copyWithZone:(NSZone *)zone{
	return [self copy];
}
-(NSData * __nonnull)data{
	return [NSData dataWithBytes:_buffer length:_length];
}
-(NSString *)description{
	return [NSString stringWithFormat:@"%@ - %s", [super description], _buffer];
}
-(NSUInteger)indexOfCharacter:(unsigned char)c{
	for (NSUInteger i = 0; i < _length; ++i) {
		if (_buffer[i] == c) {
			return i;
		}
	}
	return NSNotFound;
}
-(instancetype)init{
	return [self initWithString:@""];
}
-(instancetype)initWithChars:(const char *)chars ofLength:(NSUInteger)length{
	if ((self = [super init]) != nil){
		if (length > XUStringMaxLen){
			@throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"XUString doesn't support strings of this length." userInfo:@{
																																						 @"Chars": @(chars),
																																						 @"Length": @(length)
																																					 }];
		}
		
		for (NSUInteger i = 0; i < length; ++i){
			_buffer[i] = chars[i];
		}
		_length = (unsigned)length;
	}
	return self;
}
-(instancetype)initWithCharacterCodes:(NSArray<NSNumber *> *)codes{
	self = [self initWithString:@""];
	for (NSNumber *code in codes) {
		[self appendChar:(unsigned char)[code charValue]];
	}
	return self;
}
-(instancetype)initWithString:(NSString *)string{
	return [self initWithChars:[string UTF8String] ofLength:strlen([string UTF8String])];
}
-(BOOL)isEqualToString:(XUString *)object{
	if ([object length] != [self length]){
		return NO;
	}
	for (NSUInteger i = 0; i < _length; ++i){
		if ([self characterAtIndex:i] != [object characterAtIndex:i]){
			return NO;
		}
	}
	return YES;
}
-(unsigned int)length{
	return _length;
}
-(XUString *)MD5Digest{
	unsigned char result[16];
	CC_MD5(_buffer, (CC_LONG)[self length], result);
	
	NSString *formattedString = [NSString stringWithFormat:@"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
			result[0], result[1], result[2], result[3],
			result[4], result[5], result[6], result[7],
			result[8], result[9], result[10], result[11],
			result[12], result[13], result[14], result[15]
		];
	
	return [[XUString alloc] initWithString:formattedString];
}
-(void)removeCharacterAtIndex:(NSUInteger)index{
	for (NSUInteger i = index; i < XUStringMaxLen - 1; ++i){
		_buffer[i] = _buffer[i + 1];
	}
	_buffer[XUStringMaxLen - 1] = 0;
	
	--_length;
}
-(void)setCharacter:(unsigned char)c atIndex:(NSUInteger)index{
	_buffer[index] = c;
	
	if (index >= _length){
		_length = (unsigned)index + 1;
	}
}
-(XUString *)substringInRange:(NSRange)range{
	return [[XUString alloc] initWithChars:(const char*)&_buffer[range.location] ofLength:range.length];
}
-(const char *)string{
	return (const char *)_buffer;
}
-(XUString *)stringByAppendingString:(XUString *)string{
	XUString *copy = [string copy];
	for (NSUInteger i = 0; i < string->_length; ++i){
		[copy appendChar:[string characterAtIndex:i]];
	}
	return copy;
}
-(NSString *)stringValue{
	return [[NSString alloc] initWithUTF8String:(const char *)_buffer];
}
-(void)swapCharacterAtIndex:(NSUInteger)index1 withCharacterAtIndex:(NSUInteger)index2{
	char c1 = _buffer[index1];
	char c2 = _buffer[index2];
	
	_buffer[index2] = c1;
	_buffer[index1] = c2;
}

@end
