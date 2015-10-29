// 
// NSDateAdditions.m
// 
// Created by Charlie Monroe
// 
// Copyright (c) 2010-13 Fuel Collective, LLC. All rights reserved.
// 


#import "NSDateAdditions.h"

@implementation NSDate (FCAdditions)

+(instancetype)dateWithDay:(NSInteger)day month:(NSInteger)month year:(NSInteger)year{
	NSDateComponents *components = [[NSDateComponents alloc] init];
	[components setDay:day];
	[components setMonth:month];
	[components setYear:year];
	
	return [[NSCalendar currentCalendar] dateFromComponents:components];
}
+(instancetype)integerDate{
	NSTimeInterval interval = floor([[NSDate date] timeIntervalSince1970]);
	return [NSDate dateWithTimeIntervalSince1970:interval];
}

-(NSInteger)day{
	NSCalendar *calendar = [NSCalendar currentCalendar];
	NSDateComponents *components = [calendar components:NSCalendarUnitDay fromDate:self];
	return [components day];
}
-(NSInteger)hour{
	NSCalendar *calendar = [NSCalendar currentCalendar];
	NSDateComponents *components = [calendar components:NSCalendarUnitHour fromDate:self];
	return [components hour];
}
-(BOOL)isFuture{
	return [self timeIntervalSinceReferenceDate] > [NSDate timeIntervalSinceReferenceDate];
}
-(BOOL)isPast{
	return [self timeIntervalSinceReferenceDate] < [NSDate timeIntervalSinceReferenceDate];
}
-(BOOL)isWithinMonths:(NSUInteger)months{
	NSCalendar *calendar = [NSCalendar currentCalendar];
	NSDateComponents *components = [calendar components:NSCalendarUnitMonth fromDate:self];
	NSUInteger shift = (1 << ([components month] - 1));
	BOOL result = ((shift & months) != 0);
	return result;
}
-(BOOL)isWithinYear:(NSUInteger)year{
	NSCalendar *calendar = [NSCalendar currentCalendar];
	NSDateComponents *components = [calendar components:NSCalendarUnitYear fromDate:self];
	return [components year] == year;
}
-(NSInteger)minute{
	NSCalendar *calendar = [NSCalendar currentCalendar];
	NSDateComponents *components = [calendar components:NSCalendarUnitMinute fromDate:self];
	return [components minute];
}
-(NSInteger)month{
	NSCalendar *calendar = [NSCalendar currentCalendar];
	NSDateComponents *components = [calendar components:NSCalendarUnitMonth fromDate:self];
	return [components month];
}
-(NSInteger)second{
	NSCalendar *calendar = [NSCalendar currentCalendar];
	NSDateComponents *components = [calendar components:NSCalendarUnitSecond fromDate:self];
	return [components second];
}
-(NSString *)shortDescription{
	NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
	[formatter setDateStyle:NSDateFormatterShortStyle];
	[formatter setTimeStyle:NSDateFormatterNoStyle];
	return [formatter stringFromDate:self];
}
-(NSString *)shortEuropeanDescription{
	NSDateComponents *components = [[NSCalendar currentCalendar] components:NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear fromDate:self];
	return [NSString stringWithFormat:@"%02i.%02i.%04i", (int)[components day], (int)[components month], (int)[components year]];
}
-(NSInteger)year{
	NSCalendar *calendar = [NSCalendar currentCalendar];
	NSDateComponents *components = [calendar components:NSCalendarUnitYear fromDate:self];
	return [components year];
}

@end

