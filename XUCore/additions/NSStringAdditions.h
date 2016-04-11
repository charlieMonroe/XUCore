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
typedef NS_ENUM(NSUInteger, FCEmailAddressValidationFormat) {
	FCEmailAddressCorrectFormat,
	FCEmailAddressWrongFormat,
	FCEmailAddressPhonyFormat
};

@interface NSString (NSStringAdditions)

/** Tries to create a string from data - it first tries UTF-8 encoding, then tries
 * every other encoding available.
 */
+(nullable NSString *)stringWithData:(nullable NSData *)data DEPRECATED_MSG_ATTRIBUTE("Use the initializer on Swift's String.");

/** Uses CFUUID. */
+(nonnull NSString *)UUIDString DEPRECATED_MSG_ATTRIBUTE("Use the static variable on Swift's String.");

/** Number-like comparison by calling -[self compare:aString options:NSNumericSearch] */
-(NSComparisonResult)compareAsNumbers:(nonnull NSString *)aString DEPRECATED_ATTRIBUTE;;

/** The following two methods work with emoji chars. */
-(NSRange)composedRangeWithRange:(NSRange)range DEPRECATED_ATTRIBUTE;
-(nonnull NSString *)composedSubstringWithRange:(NSRange)range DEPRECATED_ATTRIBUTE; // Like substringWithRange, but works with emoji chars

#if TARGET_OS_IPHONE
//Returns the rect the string is drawn inside
-(CGRect)drawCenteredInRect:(CGRect)rect withAttributes:(nullable NSDictionary *)atts DEPRECATED_ATTRIBUTE;
-(CGRect)drawCenteredInRect:(CGRect)rect withFont:(nonnull UIFont *)font DEPRECATED_ATTRIBUTE;
-(CGSize)drawRightAlignedWithAttributes:(nullable NSDictionary *)atts toPoint:(CGPoint)point DEPRECATED_ATTRIBUTE;
#else
//Returns the rect the string is drawn inside
-(NSRect)drawCenteredInRect:(NSRect)rect withAttributes:(nullable NSDictionary *)attributes DEPRECATED_ATTRIBUTE;
-(NSRect)drawCenteredInRect:(NSRect)rect withFont:(nonnull NSFont *)font DEPRECATED_ATTRIBUTE;
-(NSSize)drawRightAlignedWithAttributes:(nullable NSDictionary *)atts toPoint:(NSPoint)point DEPRECATED_ATTRIBUTE;
#endif

/** Returns first character, or \0 is the string is empty. */
-(unichar)firstCharacter DEPRECATED_ATTRIBUTE;

/** Splits the string into lines and returns the first one. */
-(nonnull NSString *)firstLine DEPRECATED_ATTRIBUTE;

-(BOOL)hasCaseInsensitivePrefix:(nonnull NSString *)prefix DEPRECATED_ATTRIBUTE;
-(BOOL)hasCaseInsensitiveSuffix:(nonnull NSString *)suffix DEPRECATED_ATTRIBUTE;
-(BOOL)hasCaseInsensitiveSubstring:(nonnull NSString *)substring DEPRECATED_ATTRIBUTE;

/** Parses the string as a hex value (e.g. 0xA8). */
-(NSUInteger)hexValue DEPRECATED_ATTRIBUTE;

/** Replaces & -> &amp; etc. */
-(nonnull NSString *)HTMLEscapedString DEPRECATED_ATTRIBUTE;

/** Replaces &amp; -> & etc. */
-(nonnull NSString *)HTMLUnescapedString DEPRECATED_ATTRIBUTE;

/** Returns if the string is equal to the other string ignoring case. */
-(BOOL)isCaseInsensitivelyEqualToString:(nonnull NSString *)string DEPRECATED_ATTRIBUTE;

/** returns [self isEqualToString:@""] */
-(BOOL)isEmpty DEPRECATED_ATTRIBUTE;

/** Replaces \r, \n, \t, \u3245, etc. */
-(nonnull NSString *)JSDecodedString DEPRECATED_ATTRIBUTE;

/** Returns last character, or \0 is the string is empty. */
-(unichar)lastCharacter DEPRECATED_ATTRIBUTE;

/** You may pass NULL for error. */
-(BOOL)matchesRegexp:(nonnull NSString *)expression errorMessage:(NSString * __nullable * __nullable)error DEPRECATED_MSG_ATTRIBUTE("use XURegex");

/** Returns MD5 digest of the string. This is currently the only non-deprecated symbol on NSString. */
-(nonnull NSString *)MD5Digest;

/** Truncates the string in the middle with '...' in order to fit the width, similarily as NSTextField does. */
-(nonnull NSString *)middleTruncatedStringToFitWidth:(CGFloat)width withAttributes:(nullable NSDictionary *)atts DEPRECATED_ATTRIBUTE;

/** Range of the entire string. */
-(NSRange)range DEPRECATED_ATTRIBUTE;

/** String written back-to-front. */
-(nonnull instancetype)reverseString DEPRECATED_ATTRIBUTE;

/** Returns size with attributes, limited to width. */
-(CGSize)sizeWithAttributes:(nonnull NSDictionary *)attrs maxWidth:(CGFloat)width DEPRECATED_ATTRIBUTE;

/** Returns second character, or \0 is the string has only one character. */
-(unichar)secondCharacter DEPRECATED_ATTRIBUTE;

/** Capitalizes only first letter. */
-(nonnull NSString *)stringByCapitalizingFirstLetter DEPRECATED_ATTRIBUTE;

/** Encodes illegal URL characters (e.g. %20, etc.). */
-(nonnull NSString *)stringByEncodingIllegalURLCharacters DEPRECATED_ATTRIBUTE;

/** Decodes illegal URL characters (e.g. %20, etc.). */
-(nonnull NSString *)stringByDecodingIllegalURLCharacters DEPRECATED_ATTRIBUTE;

/** Makes the first letter lowercase. */
-(nonnull NSString *)stringByLowercasingFirstLetter DEPRECATED_ATTRIBUTE;

/** Appends enough prefix so that it has the specific length. */
-(nonnull NSString *)stringByPaddingFrontToLength:(NSUInteger)length withString:(nonnull NSString *)padString;

/** Removes characters from the set from the beginning of the string. */
-(nonnull NSString *)stringByTrimmingLeftCharactersInSet:(nonnull NSCharacterSet *)set;

/** Removes characters from the set from the end of the string. */
-(nonnull NSString *)stringByTrimmingRightCharactersInSet:(nonnull NSCharacterSet *)set;

/** Trims whitespace and newlines. */
-(nonnull NSString *)stringByTrimmingWhitespace;

/** Removes the prefix from the string. */
-(nonnull NSString *)stringByDeletingPrefix:(nonnull NSString *)prefix;

/** Removes the suffix from the string. */
-(nonnull NSString *)stringByDeletingSuffix:(nonnull NSString *)suffix;

/** Returns the suffix of length. Doesn't do any range checking. */
-(nonnull NSString *)suffixOfLength:(NSUInteger)length;

/** Uses strtoull to return ull value. */
-(unsigned long long)unsignedLongLongValue;

/** Tries several heuristics to see if the email address is valid, or even phony. */
-(FCEmailAddressValidationFormat)validateEmailAddress;

@end

