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

/** Estimated time for string.
 *
 *  @param seconds The time in seconds.
 *  @return Time string, or "Finishing" if the time supplied is less than zero.
 */
+(nonnull NSString *)estimatedTimeStringFromSeconds:(long)seconds DEPRECATED_MSG_ATTRIBUTE("This is now migrated in XUTimeUtilities");

/** Returns seconds as human-readable string. */
+(nonnull NSString *)localizedTimeStringForSeconds:(NSTimeInterval)seconds DEPRECATED_MSG_ATTRIBUTE("This is now migrated in XUTimeUtilities");

/** Tries to create a string from data - it first tries UTF-8 encoding, then tries
 * every other encoding available.
 */
+(nullable NSString *)stringWithData:(nullable NSData *)data;


/** Converts the seconds to a time string (00:00:00 format).
 *
 *  @param seconds The time in seconds.
 *  @return Time string.
 */
+(nonnull NSString *)timeStringFromSeconds:(NSTimeInterval)seconds DEPRECATED_MSG_ATTRIBUTE("This is now migrated in XUTimeUtilities");

/** Converts the seconds to a time string (00:00:00 format).
 *
 *  @param seconds The time in seconds.
 *  @param skipHours If the time is < 1 hour, only includes minutes and seconds.
 *  @return Time string.
 */
+(nonnull NSString *)timeStringFromSeconds:(NSTimeInterval)seconds skipHoursWhenZero:(BOOL)skipHours DEPRECATED_MSG_ATTRIBUTE("This is now migrated in XUTimeUtilities");

/** Uses CFUUID. */
+(nonnull NSString *)UUIDString;

/** Number-like comparison by calling -[self compare:aString options:NSNumericSearch] */
-(NSComparisonResult)compareAsNumbers:(nonnull NSString *)aString;

/** The following two methods work with emoji chars. */
-(NSRange)composedRangeWithRange:(NSRange)range;
-(nonnull NSString *)composedSubstringWithRange:(NSRange)range; // Like substringWithRange, but works with emoji chars

#if TARGET_OS_IPHONE
//Returns the rect the string is drawn inside
-(CGRect)drawCenteredInRect:(CGRect)rect withAttributes:(nullable NSDictionary *)atts;
-(CGRect)drawCenteredInRect:(CGRect)rect withFont:(nonnull UIFont *)font;
-(CGSize)drawRightAlignedWithAttributes:(nullable NSDictionary *)atts toPoint:(CGPoint)point;
#else
//Returns the rect the string is drawn inside
-(NSRect)drawCenteredInRect:(NSRect)rect withAttributes:(nullable NSDictionary *)attributes;
-(NSRect)drawCenteredInRect:(NSRect)rect withFont:(nonnull NSFont *)font;
-(NSSize)drawRightAlignedWithAttributes:(nullable NSDictionary *)atts toPoint:(NSPoint)point;
#endif

/** Returns first character, or \0 is the string is empty. */
-(unichar)firstCharacter;

/** Splits the string into lines and returns the first one. */
-(nonnull NSString *)firstLine;

-(BOOL)hasCaseInsensitivePrefix:(nonnull NSString *)prefix;
-(BOOL)hasCaseInsensitiveSuffix:(nonnull NSString *)suffix;
-(BOOL)hasCaseInsensitiveSubstring:(nonnull NSString *)substring;

/** Parses the string as a hex value (e.g. 0xA8). */
-(NSUInteger)hexValue;

/** Replaces & -> &amp; etc. */
-(nonnull NSString *)HTMLEscapedString;

/** Replaces &amp; -> & etc. */
-(nonnull NSString *)HTMLUnescapedString;

/** Returns the string written backwards. */
-(nonnull instancetype)inverseString DEPRECATED_MSG_ATTRIBUTE("Use -reverseString");

/** Returns if the string is equal to the other string ignoring case. */
-(BOOL)isCaseInsensitivelyEqualToString:(nonnull NSString *)string;

/** returns [self isEqualToString:@""] */
-(BOOL)isEmpty;

/** Replaces \r, \n, \t, \u3245, etc. */
-(nonnull NSString *)JSDecodedString;

/** Returns last character, or \0 is the string is empty. */
-(unichar)lastCharacter;

/** You may pass NULL for error. */
-(BOOL)matchesRegexp:(nonnull NSString *)expression errorMessage:(NSString * __nullable * __nullable)error DEPRECATED_MSG_ATTRIBUTE("use XURegex");;

/** Returns MD5 digest of the string. */
-(nonnull NSString *)MD5Digest;

/** Truncates the string in the middle with '...' in order to fit the width, similarily as NSTextField does. */
-(nonnull NSString *)middleTruncatedStringToFitWidth:(CGFloat)width withAttributes:(nullable NSDictionary *)atts;

/** Range of the entire string. */
-(NSRange)range;

/** String written back-to-front. */
-(nonnull instancetype)reverseString;

/** Returns size with attributes, limited to width. */
-(CGSize)sizeWithAttributes:(nonnull NSDictionary *)attrs maxWidth:(CGFloat)width;

/** Returns second character, or \0 is the string has only one character. */
-(unichar)secondCharacter;

/** Capitalizes only first letter. */
-(nonnull NSString *)stringByCapitalizingFirstLetter;

/** Encodes illegal URL characters (e.g. %20, etc.). */
-(nonnull NSString *)stringByEncodingIllegalURLCharacters;

/** Decodes illegal URL characters (e.g. %20, etc.). */
-(nonnull NSString *)stringByDecodingIllegalURLCharacters;

/** Makes the first letter lowercase. */
-(nonnull NSString *)stringByLowercasingFirstLetter;

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

