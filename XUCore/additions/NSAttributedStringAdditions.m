// 
// NSAttributedStringAdditions.m
// 
// Created by Charlie Monroe
// 
// Copyright (c) 2010-13 Fuel Collective, LLC. All rights reserved.
// 


#import "NSAttributedStringAdditions.h"


@implementation NSAttributedString (FCAdditions)

- (NSArray *)allAttachments{
	NSMutableArray *theAttachments = [NSMutableArray array];
	NSRange theStringRange = NSMakeRange(0, [self length]);
	if (theStringRange.length > 0)
	{
		NSUInteger N = 0;
		do
		{
			NSRange theEffectiveRange;
			NSDictionary *theAttributes = [self attributesAtIndex:N longestEffectiveRange:&theEffectiveRange inRange:theStringRange];
			NSTextAttachment *theAttachment = [theAttributes objectForKey:NSAttachmentAttributeName];
			if (theAttachment != NULL)
				[theAttachments addObject:theAttachment];
			N = theEffectiveRange.location + theEffectiveRange.length;
		}
		while (N < theStringRange.length);
	}
	return(theAttachments);
}

@end

