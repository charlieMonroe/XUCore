// 
// FCFileSizeTransformer.h
// 
// Created by Charlie Monroe
// 
// Copyright (c) 2010-13 Fuel Collective, LLC. All rights reserved.
// 


@import Foundation;

/*
 
 No support for reverse transform yet
 
 Input: NSNumber
 Discussion: Checks for the type via -objCType - if it's an int, checks for a negative number - if true, returns @"--"
 
 Output: NSString
 Discussion: In 0.00 kB format or @"--"
 
 */


@interface FCFileSizeTransformer : NSValueTransformer {

}

@end

// If Yes, the app will calculate the size in with base 2 (1024B = 1kB)
extern NSString *FCUseBinarySizes;

