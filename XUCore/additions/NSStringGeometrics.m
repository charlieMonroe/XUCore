// 
// NSStringGeometrics.m
// 
// Created by Charlie Monroe
// 
// Copyright (c) 2010-16 Charlie Monroe Software. All rights reserved.
// 


#import "NSStringGeometrics.h"
#import "NSStringAdditions.h"

#import <Foundation/Foundation.h>

int gNSStringGeometricsTypesetterBehavior = NSTypesetterLatestBehavior ;

@implementation NSAttributedString (Geometrics) 

#pragma mark Measure Attributed String

- (NSSize)sizeForWidth:(CGFloat)width height:(CGFloat)height {
	NSSize answer = NSZeroSize ;
	if ([self length] > 0) {
		// Checking for empty string is necessary since Layout Manager will give the nominal
		// height of one line if length is 0.  Our API specifies 0.0 for an empty string.
		NSSize size = NSMakeSize(width, height) ;
		NSTextContainer *container = [[NSTextContainer alloc] initWithContainerSize:size];
		NSTextStorage *storage = [[NSTextStorage alloc] initWithAttributedString:self];
		NSLayoutManager *layoutManager = [[NSLayoutManager alloc] init];
		[layoutManager setBackgroundLayoutEnabled:NO];
		[layoutManager addTextContainer:container] ;
		[layoutManager setHyphenationFactor:0.0] ;
		
		[storage addLayoutManager:layoutManager] ;
		
		if (gNSStringGeometricsTypesetterBehavior != NSTypesetterLatestBehavior) {
			[layoutManager setTypesetterBehavior:gNSStringGeometricsTypesetterBehavior] ;
		}
		// NSLayoutManager is lazy, so we need the following kludge to force layout:
		[layoutManager glyphRangeForTextContainer:container] ;
		
		answer = [layoutManager usedRectForTextContainer:container].size ;
		
		// In case we changed it above, set typesetterBehavior back
		// to the default value.
		gNSStringGeometricsTypesetterBehavior = NSTypesetterLatestBehavior ;
	}
	
	return answer ;
}

- (CGFloat)heightForWidth:(CGFloat)width {
	return [self sizeForWidth:width height:FLT_MAX].height ;
}

- (CGFloat)widthForHeight:(CGFloat)height {
	return [self sizeForWidth:FLT_MAX height:height].width ;
}

@end


@implementation NSString (Geometrics)

#pragma mark Given String with Attributes

- (NSSize)sizeForWidth:(CGFloat)width height:(CGFloat)height attributes:(NSDictionary*)attributes {
	NSSize answer ;
	
	NSAttributedString *astr = [[NSAttributedString alloc] initWithString:self attributes:attributes] ;
	answer = [astr sizeForWidth:width height:height] ;
	return answer ;
}

- (CGFloat)heightForWidth:(CGFloat)width attributes:(NSDictionary*)attributes {
	return [self sizeForWidth:width height:FLT_MAX attributes:attributes].height ;
}

- (CGFloat)widthForHeight:(CGFloat)height attributes:(NSDictionary*)attributes {
	return [self sizeForWidth:FLT_MAX height:height attributes:attributes].width ;
}

#pragma mark Given String with Font

- (NSSize)sizeForWidth:(CGFloat)width height:(CGFloat)height font:(NSFont*)font {
	NSSize answer = NSZeroSize ;
	
	if (font == nil) {
		NSLog(@"[%@ %@]: Error: cannot compute size with nil font", [self class], NSStringFromSelector(_cmd)) ;
	}else{
		NSDictionary* attributes = [NSDictionary dictionaryWithObjectsAndKeys:
					    font, NSFontAttributeName, nil] ;
		answer = [self sizeForWidth:width height:height attributes:attributes] ;
	}
	return answer ;
}

- (CGFloat)heightForWidth:(CGFloat)width font:(NSFont*)font {
	NSDictionary* attributes = [NSDictionary dictionaryWithObjectsAndKeys:font, (NSString*)kCTFontAttributeName, nil];
	NSAttributedString *attrStr = [[NSAttributedString alloc] initWithString:self attributes:attributes];
	
	CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString( (CFMutableAttributedStringRef) attrStr); 
	
	CGRect box = CGRectMake(0,0, width, 10000.0);
	CGMutablePathRef path = CGPathCreateMutable();
	CGPathAddRect(path, NULL, box);
	
	// Create a frame for this column and draw it.
	CTFrameRef frame = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, 0), path, NULL);
	
	CFArrayRef lineArray = CTFrameGetLines(frame);
	CFIndex lineCount = CFArrayGetCount(lineArray);
	if (lineCount == 0){
		CFRelease(path);
		CFRelease(framesetter);
		CFRelease(frame);

		return 0.0;
	}
	
	CGPoint origins;
	CFRange range = CFRangeMake(lineCount-1, 1);
	CTFrameGetLineOrigins(frame, range, &origins);
	
	CFRelease(path);
	CFRelease(framesetter);
	CFRelease(frame);
	
	return 10000.0 - origins.y + 10.0;
}

- (CGFloat)widthForHeight:(CGFloat)height font:(NSFont*)font {
	return [self sizeForWidth:FLT_MAX height:height font:font].width ;
}

@end

