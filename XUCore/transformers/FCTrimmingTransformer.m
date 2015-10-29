// 
// FCTrimmingTransformer.m
// 
// Created by Charlie Monroe
// 
// Copyright (c) 2010-13 Fuel Collective, LLC. All rights reserved.
// 


#import "FCTrimmingTransformer.h"
#import "NSStringAdditions.h"


@implementation FCTrimmingTransformer
-(id)transformedValue:(id)value{
	
	if (value == nil){
		//Or return nil? This partially solves the crash in removing selected snippet (in Kousek)...
		return @"";
	}
	
	NSAssert([value isKindOfClass:[NSString class]], @"**** FCTrimmingTransformer: value not string %@", 
		   [value class]);
	
	NSString *str = (NSString*)value;
	if ([str length] == 0){
		//The following code assumes the string has at least one character
		return str;
	}
	
	NSUInteger strLen = [str length];
	NSUInteger startIndex = 0;
	NSCharacterSet *whiteSpace = [NSCharacterSet whitespaceAndNewlineCharacterSet];
	
	while (startIndex < strLen && 
		 [whiteSpace characterIsMember:[str characterAtIndex:startIndex]]){
		++startIndex;
	}
	
	NSUInteger endIndex = startIndex;
	
	//Now get the first line
	while (endIndex < strLen && 
		 ([str characterAtIndex:endIndex] != '\n') && ([str characterAtIndex:endIndex] != '\r')){
		++endIndex;
	}

	
	return [[str substringWithRange:NSMakeRange(startIndex, (endIndex - startIndex))] stringByTrimmingWhitespace];
	
}
@end

