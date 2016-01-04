// 
// NSStringAdditions.m
// 
// Created by Charlie Monroe
// 
// Copyright (c) 2010-16 Charlie Monroe Software. All rights reserved.
// 


#import "NSStringAdditions.h"

#import <CommonCrypto/CommonDigest.h>
#import <regex.h>

#import "FCLog.h"
#import "FCLocalizationSupport.h"

#define FCNumberOfRegexMatches 1
#define FCRegexMaxErrorMessageSize 512

#ifndef XUColor
	#if TARGET_OS_IPHONE
		#define XUColor UIColor
	#else
		#define XUColor NSColor
	#endif
#endif

@implementation NSString (NSStringAdditions)
+(NSString*)estimatedTimeStringFromSeconds:(long)seconds{
	NSString *timeString = [self timeStringFromSeconds:(NSTimeInterval)seconds];
	if (timeString == nil){
		// Was below zero
		timeString = FCLocalizedString(@"Finishing...");
	}
	return timeString;
}
+(NSString *)localizedTimeStringForSeconds:(NSTimeInterval)seconds{
	NSString *hourString = @"";
	NSString *minuteString = @"";
	NSString *secondsString = @"";
	
	NSUInteger eta = seconds;
	if (eta > 3599){
		// i.e. at least one hour
		NSUInteger hours = eta / 3600;
		if (hours == 1){
			hourString = FCLocalizedString(@"1 hour");
		}else{
			hourString = FCLocalizedFormattedString(@"%lu hours", hours);
		}
	}
	
	eta %= 3600;
	if (eta > 60){
		NSUInteger minutes = eta / 60;
		if (minutes == 1){
			minuteString = FCLocalizedString(@"1 minute");
		}else{
			minuteString = FCLocalizedFormattedString(@"%lu minutes", (unsigned long)minutes);
		}
	}
	
	eta %= 60;
	if (eta > 0){
		if (eta == 1){
			secondsString = FCLocalizedString(@"1 second");
		}else{
			secondsString = FCLocalizedFormattedString(@"%lu seconds", (unsigned long)eta);
		}
	}
	
	NSString *composedString = [NSString stringWithFormat:@"%@ %@ %@", hourString, minuteString, secondsString];
	composedString = [[composedString stringByReplacingOccurrencesOfString:@"  " withString:@" "] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	
	return composedString;
}
+(NSString*)fileSizeStringFromSize:(unsigned long long)size{
	NSString *result = [NSClassFromString(@"NSByteCountFormatter") stringFromByteCount:size countStyle:NSByteCountFormatterCountStyleFile];
	if (result != nil){
		return result;
	}
	
	/* Likely OS X 10.7. */
	if (size == 0){
		return @"0 B";
	}
	
	if (size < 1024){
		return [NSString stringWithFormat:@"%i B", (int)size];
	}
	
	CGFloat floatSize = (((CGFloat)size) / 1024.0);
	if (floatSize < 1024.0){
		return [NSString stringWithFormat:@"%03.02f kB", floatSize];
	}
	
	floatSize /= 1024.0;
	if (floatSize < 1024.0){
		return [NSString stringWithFormat:@"%03.02f MB", floatSize];
	}
	
	floatSize /= 1024.0;
	return [NSString stringWithFormat:@"%03.02f GB", floatSize];
}
+(NSString *)stringWithData:(NSData *)data{
	if (data == nil){
		return nil;
	}
	
	// First try UTF8
	NSString *result = [[self alloc] initWithData:data encoding:NSUTF8StringEncoding];
	if (result){
		return result;
	}
	
	// Next try ASCII
	result = [[self alloc] initWithData:data encoding:NSASCIIStringEncoding];
	if (result){
		return result;
	}
	
	const NSStringEncoding *encodings = [NSString availableStringEncodings];
	while (encodings != NULL){
		result = [[self alloc] initWithData:data encoding:*encodings];
		if (result){
			return result;
		}
		
		++encodings;
	}
	return nil;
}
+(NSString*)timeStringFromSeconds:(NSTimeInterval)interval{
	return [self timeStringFromSeconds:interval skipHoursWhenZero:YES];
}
+(NSString*)timeStringFromSeconds:(NSTimeInterval)interval skipHoursWhenZero:(BOOL)skipHours{
	if (interval < 0) {
		return nil;
	}
	
	NSUInteger timeCp = (NSUInteger)interval;
	
	NSUInteger hours = 0;
	NSUInteger minutes = 0;
	NSUInteger seconds = 0;
	
	seconds = timeCp % 60;
	timeCp -= seconds;
	
	minutes = (timeCp % 3600)/60;
	timeCp -= minutes * 60;
	
	hours = timeCp/3600;
	
	if (hours == 0 && skipHours){
		//Skip hours
		[NSString stringWithFormat:@"%02li:%02li", (unsigned long)minutes, (unsigned long)seconds];
	}
	return [NSString stringWithFormat:@"%02li:%02li:%02li", (unsigned long)hours, (unsigned long)minutes, (unsigned long)seconds];
}
+(NSString*)UUIDString{
	CFUUIDRef uidRef = CFUUIDCreate(NULL);
	NSString *uid = CFBridgingRelease(CFUUIDCreateString(NULL, uidRef));
	CFRelease(uidRef);
	return uid;
}
-(NSComparisonResult)compareAsNumbers:(NSString *)aString{
	return [self compare:aString options:NSNumericSearch];
}
- (NSRange)composedRangeWithRange:(NSRange)range{
	// We're going to make a new range that takes into account surrogate unicode pairs (composed characters)
	__block NSRange adjustedRange = range;
	
	// Adjust the location
	[self enumerateSubstringsInRange:NSMakeRange(0, range.location + 1) options:NSStringEnumerationByComposedCharacterSequences usingBlock:^(NSString *substring, NSRange substringRange, NSRange enclosingRange, BOOL *stop) {
		// If they string the iterator found is greater than 1 in length, add that to range location.
		// This means that there is a composed character before where the range starts who's length is greater than 1.
		adjustedRange.location += substring.length - 1;
	}];
	
	// Adjust the length
	NSInteger length = self.length;
	
	// Count how many times we iterate so we only iterate over what we care about.
	__block NSInteger count = 0;
	[self enumerateSubstringsInRange:NSMakeRange(adjustedRange.location, length - adjustedRange.location) options:NSStringEnumerationByComposedCharacterSequences usingBlock:^(NSString *substring, NSRange substringRange, NSRange enclosingRange, BOOL *stop) {
		// If they string the iterator found is greater than 1 in length, add that to range length.
		// This means that there is a composed character inside of the range starts who's length is greater than 1.
		adjustedRange.length += substring.length - 1;
		
		// Add one to the count
		count++;
		
		// If we have iterated as many times as the original length, stop.
		if (range.length == count) {
			*stop = YES;
		}
	}];
	
	// Make sure we don't make an invalid range. This should never happen, but let's play it safe anyway.
	if (adjustedRange.location + adjustedRange.length > length) {
		adjustedRange.length = length - adjustedRange.location - 1;
	}
	
	// Return the adjusted range
	return adjustedRange;
}
- (NSString *)composedSubstringWithRange:(NSRange)range {
	// Return a substring using a composed range so surrogate unicode pairs (composed characters) count as 1 in the
	// range instead of however many unichars they actually are.
	return [self substringWithRange:[self composedRangeWithRange:range]];
}


#if TARGET_OS_IPHONE
-(CGRect)drawCenteredInRect:(CGRect)rect withAttributes:(NSDictionary *)atts{
	CGSize stringSize = [self sizeWithAttributes:atts];
	[self drawAtPoint:CGPointMake(CGRectGetMidX(rect) - stringSize.width / 2.0, CGRectGetMidY(rect) - stringSize.height / 2.0) withAttributes:atts];
	return CGRectMake(CGRectGetMidX(rect) - stringSize.width / 2.0, CGRectGetMidY(rect) - stringSize.height / 2.0, stringSize.width, stringSize.height);
}
-(CGRect)drawCenteredInRect:(CGRect)rect withFont:(UIFont *)font{
	NSDictionary *atts = @{ NSFontAttributeName : font };
	return [self drawCenteredInRect:rect withAttributes:atts];
}
-(CGSize)drawRightAlignedWithAttributes:(NSDictionary *)atts toPoint:(CGPoint)point{
	CGSize s = [self sizeWithAttributes:atts];
	[self drawAtPoint:CGPointMake(point.x - s.width, point.y) withAttributes:atts];
	return s;
}
#else
-(NSRect)drawCenteredInRect:(NSRect)rect withAttributes:(NSDictionary*)attributes{
	NSSize stringSize = [self sizeWithAttributes:attributes];
	[self drawAtPoint:NSMakePoint(NSMinX(rect) + NSWidth(rect)/2.0 - stringSize.width / 2.0, NSMinY(rect) + NSHeight(rect)/2.0 - stringSize.height / 2.0) withAttributes:attributes];
	return NSMakeRect(NSMinX(rect) + NSWidth(rect)/2.0 - stringSize.width / 2.0, NSMinY(rect) + NSHeight(rect)/2.0 - stringSize.height / 2.0, stringSize.width, stringSize.height);
}
-(NSRect)drawCenteredInRect:(NSRect)rect withFont:(NSFont*)font{
	return [self drawCenteredInRect:rect withAttributes:[NSDictionary dictionaryWithObject:font forKey:NSFontAttributeName]];
}
-(NSSize)drawRightAlignedWithAttributes:(NSDictionary*)atts toPoint:(NSPoint)point{
	NSSize s = [self sizeWithAttributes:atts];
	[self drawAtPoint:NSMakePoint(point.x - s.width, point.y) withAttributes:atts];
	return s;
}
#endif
-(NSString*)escapedString{
	return [self HTMLEscapedString];
}
-(NSString *)HTMLEscapedString{
	NSMutableString *string = [NSMutableString stringWithString: self];
	
	[string replaceOccurrencesOfString: @"&"  withString: @"&amp;" options: NSLiteralSearch range: NSMakeRange(0, [string length])];
	[string replaceOccurrencesOfString: @"\"" withString: @"&quot;" options: NSLiteralSearch range: NSMakeRange(0, [string length])];
	[string replaceOccurrencesOfString: @"'"  withString: @"&#x27;" options: NSLiteralSearch range: NSMakeRange(0, [string length])];
	[string replaceOccurrencesOfString: @">"  withString: @"&gt;" options: NSLiteralSearch range: NSMakeRange(0, [string length])];
	[string replaceOccurrencesOfString: @"<"  withString: @"&lt;" options: NSLiteralSearch range: NSMakeRange(0, [string length])];
	
	return [NSString stringWithString:string];
}
-(NSString *)inverseString{
	return [self reverseString];
}
-(BOOL)isCaseInsensitivelyEqualToString:(NSString*)string{
	return [self compare:string options:NSCaseInsensitiveSearch range:[self range]] == NSOrderedSame;
}
-(BOOL)isEmpty{
	return [self isEqualToString:@""];
}
-(unichar)firstCharacter{
	if ([self length] == 0){
		return '\0';
	}
	return [self characterAtIndex:0];
}
-(NSString *)firstLine{
	return [[self componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]] firstObject];
}
-(BOOL)hasCaseInsensitivePrefix:(NSString*)prefix{
	return [self rangeOfString:prefix options:( NSCaseInsensitiveSearch | NSAnchoredSearch ) range:[self range]].location != NSNotFound;
}

-(BOOL)hasCaseInsensitiveSuffix:(NSString*)suffix{
	return [self rangeOfString:suffix options:( NSCaseInsensitiveSearch | NSBackwardsSearch | NSAnchoredSearch ) range:[self range]].location != NSNotFound;
}

-(BOOL)hasCaseInsensitiveSubstring:(NSString*)substring{
	return [self rangeOfString:substring options:NSCaseInsensitiveSearch range:[self range]].location != NSNotFound;
}
-(NSUInteger)hexValue{
	NSArray *components = [self componentsSeparatedByString:@"x"];
	NSString *suffix = [components count] < 2 ? self : [components objectAtIndex:1];
	suffix = [suffix stringByTrimmingLeftCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"0"]];
	
	NSUInteger result = 0;
	
	NSUInteger start = 0;
	for (NSUInteger i = start; i < [suffix length]; ++i){
		unichar c = [suffix characterAtIndex:i];
		if (c >= '0' && c <= '9'){
			result *= 16;
			result += (c - '0');
		}else if (c >= 'a' && c <= 'f'){
			result *= 16;
			result += (c - 'a') + 10;
		}else if (c >= 'A' && c <= 'F'){
			result *= 16;
			result += (c - 'A') + 10;
		}else{
			break;
		}
	}
	return result;
}
-(NSString *)JSDecodedString{
	NSMutableString *result = [self mutableCopy];
	[result replaceOccurrencesOfString:@"\\r" withString:[NSString stringWithFormat:@"%C", (unichar)13] options:0 range:NSMakeRange(0, [result length])];
	[result replaceOccurrencesOfString:@"\\n" withString:[NSString stringWithFormat:@"%C", (unichar)10] options:0 range:NSMakeRange(0, [result length])];
	[result replaceOccurrencesOfString:@"\\t" withString:[NSString stringWithFormat:@"%C", (unichar)9] options:0 range:NSMakeRange(0, [result length])];
	
	NSUInteger i = 0;
	while (i < [self length]){
		unichar c = [self characterAtIndex:i];
		if (c == '\\' && i < [self length] - 1){
			unichar nextC = [self characterAtIndex:i + 1];
			if (nextC == 'u' && [self length] - 6){
				NSString *unicodeCharCode = [self substringWithRange:NSMakeRange(i + 2, 4)];
				unichar replacementChar = (unichar)[unicodeCharCode hexValue];
				[result replaceOccurrencesOfString:[NSString stringWithFormat:@"\\u%@", unicodeCharCode] withString:[NSString stringWithFormat:@"%C", replacementChar] options:0 range:NSMakeRange(0, [result length])];
				
				i += 6;
				continue;
			}
		}
		
		++i;
	}
	
	return result;
}
-(unichar)lastCharacter{
	NSUInteger len = [self length];
	if (len == 0){
		return '\0';
	}
	
	return [self characterAtIndex:len - 1];
}
-(BOOL)matchesRegexp:(NSString*)expression errorMessage:(NSString**)error{
	int isFail;
	
	const char *regexPattern = [expression UTF8String];
	
	regex_t regex;
	regmatch_t pmatch[FCNumberOfRegexMatches]; // track up to 1 maches. Actually only one is needed.
	
	const char *sourceCString;
	char errorMessage[FCRegexMaxErrorMessageSize];
	
	NSString *errorMessageString;
	
	sourceCString = [self UTF8String];
	
	// setup the regular expression
	
	@try{
		
		if( (isFail = regcomp(&regex, regexPattern, REG_EXTENDED)) > 0 ){
			regerror(isFail, &regex, errorMessage, FCRegexMaxErrorMessageSize);
			errorMessageString = [NSString stringWithUTF8String:errorMessage];
			
			goto regexp_fail;
		}else{
			if( (isFail = regexec( &regex, sourceCString, FCNumberOfRegexMatches, pmatch, 0 )) > 0 ){
				regerror( isFail, &regex, errorMessage, FCRegexMaxErrorMessageSize );
				errorMessageString = [NSString stringWithUTF8String:errorMessage];
				goto regexp_fail;
			}else{
				goto regexp_success;
			}
		}
	}@catch (NSException *exception) {
		goto regexp_fail;
	}

regexp_success:
	regfree(&regex);
	if (error != nil){
		*error = nil;
	}
	return YES;
regexp_fail:
	regfree(&regex);
	if (error != nil){
		*error = errorMessageString;
	}
	return NO;
}

-(NSString *)MD5Digest{
	const char *cstr = [self UTF8String];
	unsigned char result[16];
	CC_MD5(cstr, (CC_LONG)strlen(cstr), result);
	
	return [NSString stringWithFormat:@"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
			result[0], result[1], result[2], result[3],
			result[4], result[5], result[6], result[7],
			result[8], result[9], result[10], result[11],
			result[12], result[13], result[14], result[15]
		];
}
-(NSString *)middleTruncatedStringToFitWidth:(CGFloat)width withAttributes:(NSDictionary *)atts{
	NSString *front = nil;
	NSString *tail = nil;
	NSUInteger frontIndex = [self length] / 2;
	NSUInteger tailIndex = frontIndex;
	
	NSString *result = self;
#if !TARGET_OS_IPHONE
	NSSize size = [result sizeWithAttributes:atts];
#else
	CGSize size = [result sizeWithAttributes:atts];
#endif
	
	while (size.width > width) {
		--frontIndex;
		++tailIndex;
		
		front = [self substringToIndex:frontIndex];
		tail = [self substringFromIndex:tailIndex];
		result = [NSString stringWithFormat:@"%@...%@", front, tail];
		size = [result sizeWithAttributes:atts];
	}
	
	return result;
}

-(NSRange)range{
	return NSMakeRange(0, [self length]);
}
-(instancetype)reverseString{
	NSMutableString *result = [NSMutableString string];
	[self enumerateSubstringsInRange:[self range] options:NSStringEnumerationReverse | NSStringEnumerationByComposedCharacterSequences usingBlock:^(NSString *substring, NSRange substringRange, NSRange enclosingRange, BOOL *stop) {
		[result appendString:substring];
	}];
	return result;
}
-(unichar)secondCharacter{
	if ([self length] < 2){
		return '\0';
	}
	return [self characterAtIndex:1];
}
#if TARGET_OS_IPHONE
-(CGSize)sizeWithFont:(UIFont*)font maxWidth:(CGFloat)width{
	CGSize constraintSize;
	constraintSize.width = width;
	constraintSize.height = MAXFLOAT;
	return [self boundingRectWithSize:constraintSize options:NSStringDrawingUsesLineFragmentOrigin attributes:@{ NSFontAttributeName : font } context:nil].size;
}
#endif
-(CGSize)sizeWithAttributes:(NSDictionary *)attrs maxWidth:(CGFloat)width{
	CGSize constraintSize;
	constraintSize.width = width;
	constraintSize.height = MAXFLOAT;
	return [self boundingRectWithSize:constraintSize options:NSStringDrawingUsesLineFragmentOrigin attributes:attrs
					#if TARGET_OS_IPHONE
					  context:nil // Additional iOS argument
					#endif
			].size;
}
-(NSString *)stringByCapitalizingFirstLetter{
	if ([self length] == 0){
		return self;
	}
	NSMutableString *result = [self mutableCopy];
	[result replaceCharactersInRange:NSMakeRange(0, 1) withString:[[self substringWithRange:NSMakeRange(0, 1)] capitalizedString]];
	return result;
}
-(NSString *)stringByDeletingPrefix:(NSString *)prefix{
	if (![self hasPrefix:prefix]){
		return self;
	}
	return [self substringFromIndex:[prefix length]];
}
-(NSString *)stringByDeletingSuffix:(NSString *)suffix{
	if (![self hasSuffix:suffix]){
		return self;
	}
	return [self substringWithRange:NSMakeRange(0, [self length] - [suffix length])];
}
-(NSString*)stringByEncodingIllegalURLCharacters{
	return CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes( NULL, (CFStringRef)self, NULL, CFSTR( ",;:/?@&$=|^~`\{}[]" ), kCFStringEncodingUTF8 ));
}

-(NSString*)stringByDecodingIllegalURLCharacters{
	return CFBridgingRelease(CFURLCreateStringByReplacingPercentEscapes( NULL, (CFStringRef)self, CFSTR( "" ) ));
}
-(NSString *)stringByLowercasingFirstLetter{
	if ([self length] == 0){
		return self;
	}
	NSMutableString *result = [self mutableCopy];
	[result replaceCharactersInRange:NSMakeRange(0, 1) withString:[[self substringWithRange:NSMakeRange(0, 1)] lowercaseString]];
	return result;
}
-(NSString *)stringByPaddingFrontToLength:(NSUInteger)length withString:(NSString *)padString{
	NSString *result = self;
	while ([result length] < length) {
		result = [padString stringByAppendingString:result];
	}
	return result;
}
-(NSString*)stringByTrimmingLeftCharactersInSet:(NSCharacterSet *)set{
	NSUInteger start = 0;
	while (start < [self length] && [set characterIsMember:[self characterAtIndex:start]]) {
		++start;
	}
	return [self substringFromIndex:start];
}
-(NSString *)stringByTrimmingRightCharactersInSet:(NSCharacterSet *)set{
	NSUInteger stop = [self length] - 1;
	while (stop > 0){
		if ([set characterIsMember:[self characterAtIndex:stop]]){
			--stop;
		}else{
			break;
		}
	}
	++stop;
	return [self substringToIndex:stop];
}
-(NSString *)stringByTrimmingWhitespace{
	return [self stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}
-(NSString *)suffixOfLength:(NSUInteger)length{
	return [self substringWithRange:NSMakeRange([self length] - length, length)];
}
-(NSString*)trimmedString{
	return [self stringByTrimmingWhitespace];
}
-(NSString*)unescapedString{
	return [self HTMLUnescapedString];
}
-(NSString *)HTMLUnescapedString{
	NSMutableString *string = [NSMutableString stringWithString: self];
	
	[string replaceOccurrencesOfString: @"&nbsp;"  withString: @" " options: NSLiteralSearch range: NSMakeRange(0, [string length])];
	[string replaceOccurrencesOfString: @"&amp;"  withString: @"&" options: NSLiteralSearch range: NSMakeRange(0, [string length])];
	[string replaceOccurrencesOfString: @"&quot;" withString: @"\"" options: NSLiteralSearch range: NSMakeRange(0, [string length])];
	[string replaceOccurrencesOfString: @"&#x27;" withString: @"'" options: NSLiteralSearch range: NSMakeRange(0, [string length])];
	[string replaceOccurrencesOfString: @"&#x39;" withString: @"'" options: NSLiteralSearch range: NSMakeRange(0, [string length])];
	[string replaceOccurrencesOfString: @"&#x92;" withString: @"'" options: NSLiteralSearch range: NSMakeRange(0, [string length])];
	[string replaceOccurrencesOfString: @"&#x96;" withString: @"'" options: NSLiteralSearch range: NSMakeRange(0, [string length])];
	[string replaceOccurrencesOfString: @"&gt;" withString: @">" options: NSLiteralSearch range: NSMakeRange(0, [string length])];
	[string replaceOccurrencesOfString: @"&lt;" withString: @"<" options: NSLiteralSearch range: NSMakeRange(0, [string length])];
	[string replaceOccurrencesOfString: @"&apos;"  withString: @"'" options: NSLiteralSearch range: NSMakeRange(0, [string length])];
	
	NSUInteger i = 0;
	while (i < [self length]){
		unichar c = [self characterAtIndex:i];
		if (c == '&' && i < [self length] - 1){
			unichar nextC = [self characterAtIndex:i + 1];
			if (nextC == '#'){
				NSUInteger length = 0;
				while (i + length + 2 < [self length]) {
					unichar cc = [self characterAtIndex:i + length + 2];
					if (cc >= '0' && cc <= '9'){
						++length;
						continue;
					}
					break;
				}
				NSString *unicodeCharCode = [self substringWithRange:NSMakeRange(i + 2, length)];
				unichar replacementChar = (unichar)[unicodeCharCode intValue];
				[string replaceOccurrencesOfString:[NSString stringWithFormat:@"&#%@;", unicodeCharCode] withString:[NSString stringWithFormat:@"%C", replacementChar] options:0 range:NSMakeRange(0, [string length])];
				
				i += 6;
				continue;
			}
		}
		
		++i;
	}
	
	return [NSString stringWithString: string];
}
-(unsigned long long)unsignedLongLongValue{
	return strtoull([self UTF8String], NULL, 0);
}

-(FCEmailAddressValidationFormat)validateEmailAddress{
	// First see if it fits the general description
	if (![self matchesRegexp:@"..*@..*\\..[^/]*" errorMessage:nil]){
		return FCEmailAddressWrongFormat;
	}
	
	// It's about right, see for some obviously phony emails
	if ([self hasCaseInsensitiveSubstring:@"fuck"] || [self hasCaseInsensitiveSubstring:@"shit"] 
	    || [self hasCaseInsensitiveSubstring:@"qwert"] || [self hasCaseInsensitiveSubstring:@"asdf"]
	    || [self hasCaseInsensitiveSubstring:@"mail@mail.com"]
	    || [self matchesRegexp:@"^.@.\\..*" errorMessage:nil]){ /* a@a.com */
		return FCEmailAddressPhonyFormat;
	}
	
	if ([self rangeOfString:@" "].location != NSNotFound){
		return FCEmailAddressWrongFormat;
	}
	
	return FCEmailAddressCorrectFormat;
}

@end

