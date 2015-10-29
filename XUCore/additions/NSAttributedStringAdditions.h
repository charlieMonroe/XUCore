// 
// NSAttributedStringAdditions.h
// 
// Created by Charlie Monroe
// 
// Copyright (c) 2010-13 Fuel Collective, LLC. All rights reserved.
// 

@import Foundation;

#if TARGET_OS_IPHONE
	@import UIKit;
#else
	@import Cocoa;
#endif


@interface NSAttributedString (FCAdditions)

- (NSArray *)allAttachments;

@end

