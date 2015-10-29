//
//  XUString.h
//  DownieCore
//
//  Created by Charlie Monroe on 5/14/15.
//  Copyright (c) 2015 Charlie Monroe Software. All rights reserved.
//

#import <Foundation/Foundation.h>

/** This is a class that helps dealing with various string computations by
 * allowing direct modification of characters in the string. Note that the
 * string is limited to 512 chars at this moment - the string is allocated
 * with the object as a char array and no further allocations are made to make
 * it as fast as possible.
 */
@interface XUString : NSObject <NSCopying>

+(nonnull instancetype)string;

/** Convenience method that fills the string with str[0] = 0, str[1] = 1, ... */
+(nonnull instancetype)stringFilledWithASCIITableOfLength:(NSUInteger)length;

/** Convenience method that fills the string with c. */
+(nonnull instancetype)stringFilledWithChar:(char)c ofLength:(NSUInteger)length;

+(nonnull instancetype)stringWithString:(nonnull NSString *)string;

/** Interprets NSData as a const char * */
+(nonnull instancetype)stringWithDataBytes:(nonnull NSData *)data;


/// Returns the first index of c, or NSNotFound.
-(NSUInteger)indexOfCharacter:(unsigned char)c;

/// Takes an array of NSNumber's which represent individual chars.
-(nonnull instancetype)initWithCharacterCodes:(nonnull NSArray<NSNumber *> *)codes;

-(nonnull instancetype)initWithChars:(nonnull const char *)chars ofLength:(NSUInteger)length NS_DESIGNATED_INITIALIZER;
-(nonnull instancetype)initWithString:(nonnull NSString *)string;

-(BOOL)isEqualToString:(nullable XUString *)object;

-(void)appendChar:(unsigned char)c;
-(unsigned char)characterAtIndex:(NSUInteger)index;

/** Removes character at index by shifting the remainder of the string left. */
-(void)removeCharacterAtIndex:(NSUInteger)index;

-(void)setCharacter:(unsigned char)c atIndex:(NSUInteger)index;

-(nonnull XUString *)stringByAppendingString:(nonnull XUString *)string;

-(nonnull XUString *)substringInRange:(NSRange)range;

-(void)swapCharacterAtIndex:(NSUInteger)index1 withCharacterAtIndex:(NSUInteger)index2;


/** Returns bytes wrapped in NSData. */
@property (readonly, nonnull, nonatomic) NSData *data;

@property (readonly, nonnull, nonatomic) XUString *MD5Digest;
@property (readonly, nonnull, nonatomic) const char *string NS_RETURNS_INNER_POINTER;

/** Convenience property that returns [NSString stringWithUTF8String:...] */
@property (readonly, nonnull, nonatomic) NSString *stringValue;

@property (readonly, nonatomic) unsigned length;


@end
