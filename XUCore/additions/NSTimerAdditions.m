// 
// NSTimerAdditions.m
// 
// Created by Charlie Monroe
// 
// Copyright (c) 2010-13 Fuel Collective, LLC. All rights reserved.
// 


#import "NSTimerAdditions.h"

@implementation NSTimer (NSTimerAdditions)

+(void)__executionMethod:(NSTimer*)timer{
	void (^block)(NSTimer *) = [timer userInfo];
	block(timer);
}

+(NSTimer *)scheduledTimerWithTimeInterval:(NSTimeInterval)seconds repeats:(BOOL)repeats usingBlock:(void (^)(NSTimer *timer))fireBlock{
	return [self scheduledTimerWithTimeInterval:seconds target:self selector:@selector(__executionMethod:) userInfo:[fireBlock copy] repeats:repeats];
}
+(NSTimer *)timerWithTimeInterval:(NSTimeInterval)seconds repeats:(BOOL)repeats usingBlock:(void (^)(NSTimer *timer))fireBlock{
	return [self timerWithTimeInterval:seconds target:self selector:@selector(__executionMethod:) userInfo:[fireBlock copy] repeats:repeats];
}

@end

