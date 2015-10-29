// 
// FCRandomGenerator.h
// 
// Created by Charlie Monroe
// 
// Copyright (c) 2010-13 Fuel Collective, LLC. All rights reserved.
// 


#import <Foundation/Foundation.h>


@interface FCRandomGenerator : NSObject {

}

+(FCRandomGenerator*)randomGenerator;

-(unsigned char)randomByte;

-(NSUInteger)randomUnsignedInteger;
-(NSUInteger)randomUnsignedIntegerInRange:(NSRange)range;
-(NSUInteger)randomUnsignedIntegerOfMaxValue:(NSUInteger)max;

-(unsigned long long)randomUnsignedLongLong;

@end

