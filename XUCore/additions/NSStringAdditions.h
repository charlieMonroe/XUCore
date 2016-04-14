// 
// NSStringAdditions.h
// 
// Created by Charlie Monroe
// 
// Copyright (c) 2010-16 Charlie Monroe Software. All rights reserved.
// 


#import <Foundation/Foundation.h>

#if TARGET_OS_IPHONE
	#define TARGET_IOS 1
	#import <UIKit/UIKit.h>
#else
	#import <AppKit/AppKit.h>
#endif


/** Return value from -validateEmailAddress */
DEPRECATED_ATTRIBUTE
typedef NS_ENUM(NSUInteger, FCEmailAddressValidationFormat) {
	FCEmailAddressCorrectFormat,
	FCEmailAddressWrongFormat,
	FCEmailAddressPhonyFormat
};

@interface NSString (NSStringAdditions)

/** Tries to create a string from data - it first tries UTF-8 encoding, then tries
 * every other encoding available.
 */
+(nullable NSString *)stringWithData:(nullable NSData *)data NS_SWIFT_UNAVAILABLE("Use Swift's String.");

/** Uses CFUUID. */
+(nonnull NSString *)UUIDString NS_SWIFT_UNAVAILABLE("Use Swift's String.");

/** Number-like comparison by calling -[self compare:aString options:NSNumericSearch] */
-(NSComparisonResult)compareAsNumbers:(nonnull NSString *)aString NS_SWIFT_UNAVAILABLE("Use Swift's String.");

/** The following two methods work with emoji chars. */
-(NSRange)composedRangeWithRange:(NSRange)range NS_SWIFT_UNAVAILABLE("Use Swift's String.");
-(nonnull NSString *)composedSubstringWithRange:(NSRange)range NS_SWIFT_UNAVAILABLE("Use Swift's String."); // Like substringWithRange, but works with emoji chars

#if TARGET_OS_IPHONE
//Returns the rect the string is drawn inside
-(CGRect)drawCenteredInRect:(CGRect)rect withAttributes:(nullable NSDictionary *)atts NS_SWIFT_UNAVAILABLE("Use Swift's String.");
-(CGRect)drawCenteredInRect:(CGRect)rect withFont:(nonnull UIFont *)font NS_SWIFT_UNAVAILABLE("Use Swift's String.");
-(CGSize)drawRightAlignedWithAttributes:(nullable NSDictionary *)atts toPoint:(CGPoint)point NS_SWIFT_UNAVAILABLE("Use Swift's String.");
#else
//Returns the rect the string is drawn inside
-(NSRect)drawCenteredInRect:(NSRect)rect withAttributes:(nullable NSDictionary *)attributes NS_SWIFT_UNAVAILABLE("Use Swift's String.");
-(NSRect)drawCenteredInRect:(NSRect)rect withFont:(nonnull NSFont *)font NS_SWIFT_UNAVAILABLE("Use Swift's String.");
-(NSSize)drawRightAlignedWithAttributes:(nullable NSDictionary *)atts toPoint:(NSPoint)point NS_SWIFT_UNAVAILABLE("Use Swift's String.");
#endif

/** Returns first character, or \0 is the string is empty. */
-(unichar)firstCharacter NS_SWIFT_UNAVAILABLE("Use Swift's String.");

/** Splits the string into lines and returns the first one. */
-(nonnull NSString *)firstLine NS_SWIFT_UNAVAILABLE("Use Swift's String.");

-(BOOL)hasCaseInsensitivePrefix:(nonnull NSString *)prefix NS_SWIFT_UNAVAILABLE("Use Swift's String.");
-(BOOL)hasCaseInsensitiveSuffix:(nonnull NSString *)suffix NS_SWIFT_UNAVAILABLE("Use Swift's String.");
-(BOOL)hasCaseInsensitiveSubstring:(nonnull NSString *)substring NS_SWIFT_UNAVAILABLE("Use Swift's String.");

/** Parses the string as a hex value (e.g. 0xA8). */
-(NSUInteger)hexValue NS_SWIFT_UNAVAILABLE("Use Swift's String.");

/** Replaces & -> &amp; etc. */
-(nonnull NSString *)HTMLEscapedString NS_SWIFT_UNAVAILABLE("Use Swift's String.");

/** Replaces &amp; -> & etc. */
-(nonnull NSString *)HTMLUnescapedString NS_SWIFT_UNAVAILABLE("Use Swift's String.");

/** Returns if the string is equal to the other string ignoring case. */
-(BOOL)isCaseInsensitivelyEqualToString:(nonnull NSString *)string NS_SWIFT_UNAVAILABLE("Use Swift's String.");

/** returns [self isEqualToString:@""] */
-(BOOL)isEmpty DEPRECATED_ATTRIBUTE;

/** Replaces \r, \n, \t, \u3245, etc. */
-(nonnull NSString *)JSDecodedString NS_SWIFT_UNAVAILABLE("Use Swift's String.");

/** Returns last character, or \0 is the string is empty. */
-(unichar)lastCharacter NS_SWIFT_UNAVAILABLE("Use Swift's String.");

/** You may pass NULL for error. */
-(BOOL)matchesRegexp:(nonnull NSString *)expression errorMessage:(NSString * __nullable * __nullable)error DEPRECATED_MSG_ATTRIBUTE("use XURegex");

/** Returns MD5 digest of the string. This is currently the only non-deprecated symbol on NSString. */
-(nonnull NSString *)MD5Digest;

/** Truncates the string in the middle with '...' in order to fit the width, similarily as NSTextField does. */
-(nonnull NSString *)middleTruncatedStringToFitWidth:(CGFloat)width withAttributes:(nullable NSDictionary *)atts NS_SWIFT_UNAVAILABLE("Use Swift's String.");

/** Range of the entire string. */
-(NSRange)range NS_SWIFT_UNAVAILABLE("Use Swift's String.");

/** String written back-to-front. */
-(nonnull instancetype)reverseString NS_SWIFT_UNAVAILABLE("Use Swift's String.");

/** Returns size with attributes, limited to width. */
-(CGSize)sizeWithAttributes:(nonnull NSDictionary *)attrs maxWidth:(CGFloat)width NS_SWIFT_UNAVAILABLE("Use Swift's String.");

/** Returns second character, or \0 is the string has only one character. */
-(unichar)secondCharacter NS_SWIFT_UNAVAILABLE("Use Swift's String.");

/** Capitalizes only first letter. */
-(nonnull NSString *)stringByCapitalizingFirstLetter NS_SWIFT_UNAVAILABLE("Use Swift's String.");

/** Encodes illegal URL characters (e.g. %20, etc.). */
-(nonnull NSString *)stringByEncodingIllegalURLCharacters NS_SWIFT_UNAVAILABLE("Use Swift's String.");

/** Decodes illegal URL characters (e.g. %20, etc.). */
-(nonnull NSString *)stringByDecodingIllegalURLCharacters NS_SWIFT_UNAVAILABLE("Use Swift's String.");

/** Makes the first letter lowercase. */
-(nonnull NSString *)stringByLowercasingFirstLetter NS_SWIFT_UNAVAILABLE("Use Swift's String.");

/** Appends enough prefix so that it has the specific length. */
-(nonnull NSString *)stringByPaddingFrontToLength:(NSUInteger)length withString:(nonnull NSString *)padString NS_SWIFT_UNAVAILABLE("Use Swift's String.");

/** Removes characters from the set from the beginning of the string. */
-(nonnull NSString *)stringByTrimmingLeftCharactersInSet:(nonnull NSCharacterSet *)set NS_SWIFT_UNAVAILABLE("Use Swift's String.");

/** Removes characters from the set from the end of the string. */
-(nonnull NSString *)stringByTrimmingRightCharactersInSet:(nonnull NSCharacterSet *)set NS_SWIFT_UNAVAILABLE("Use Swift's String.");

/** Trims whitespace and newlines. */
-(nonnull NSString *)stringByTrimmingWhitespace NS_SWIFT_UNAVAILABLE("Use Swift's String.");

/** Removes the prefix from the string. */
-(nonnull NSString *)stringByDeletingPrefix:(nonnull NSString *)prefix NS_SWIFT_UNAVAILABLE("Use Swift's String.");

/** Removes the suffix from the string. */
-(nonnull NSString *)stringByDeletingSuffix:(nonnull NSString *)suffix NS_SWIFT_UNAVAILABLE("Use Swift's String.");

/** Returns the suffix of length. Doesn't do any range checking. */
-(nonnull NSString *)suffixOfLength:(NSUInteger)length NS_SWIFT_UNAVAILABLE("Use Swift's String.");

/** Uses strtoull to return ull value. */
-(unsigned long long)unsignedLongLongValue NS_SWIFT_UNAVAILABLE("Use Swift's String.");

/** Tries several heuristics to see if the email address is valid, or even phony. */
-(FCEmailAddressValidationFormat)validateEmailAddress DEPRECATED_ATTRIBUTE;

@end

