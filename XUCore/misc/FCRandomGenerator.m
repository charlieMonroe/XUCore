// 
// FCRandomGenerator.m
// 
// Created by Charlie Monroe
// 
// Copyright (c) 2010-13 Fuel Collective, LLC. All rights reserved.
// 


#import "FCRandomGenerator.h"
#include <sys/time.h>

static FCRandomGenerator *_randomGenerator;

@implementation FCRandomGenerator
+(FCRandomGenerator *)randomGenerator{
	if (_randomGenerator == nil){
		_randomGenerator = [[self alloc] init];
	}
	return _randomGenerator;
}

-(instancetype)init{
	if ((self = [super init]) != nil){
		struct timeval tv; 
		unsigned long junk = (unsigned long)&tv;
		
		gettimeofday(&tv, NULL); 
		srandom((unsigned int)((getpid() << 16) ^ tv.tv_sec ^ tv.tv_usec ^ junk));
	}
	return self;
}
-(unsigned char)randomByte{
	return random() % 256;
}
-(NSUInteger)randomUnsignedInteger{
	return (NSUInteger)random();
}
-(NSUInteger)randomUnsignedIntegerInRange:(NSRange)range{
	return range.location + ([self randomUnsignedInteger] % range.length);
}
-(NSUInteger)randomUnsignedIntegerOfMaxValue:(NSUInteger)max{
	return [self randomUnsignedIntegerInRange:NSMakeRange(0, max)];
}
-(unsigned long long)randomUnsignedLongLong{
	unsigned long long value = random();
	value = value << 32;
	value |= random();
	return value;
}
@end

