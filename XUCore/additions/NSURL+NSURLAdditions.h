// 
// NSURL+NSURLAdditions.h
// 
// Created by Charlie Monroe
// 
// Copyright (c) 2010-13 Fuel Collective, LLC. All rights reserved.
// 


#import <Foundation/Foundation.h>

@interface NSURL (NSURLAdditions)

+(id)fileReferenceURLWithPath:(NSString *)path;

-(NSInteger)fileSize;
-(NSString*)fileSizeString;

@end

