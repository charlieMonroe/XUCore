// 
// NSDateAdditions.h
// 
// Created by Charlie Monroe
// 
// Copyright (c) 2010-13 Fuel Collective, LLC. All rights reserved.
// 


#import <Foundation/Foundation.h>


@interface NSDate (FCAdditions)

/** Returns a date with day, month and year. */
+(nullable instancetype)dateWithDay:(NSInteger)day month:(NSInteger)month year:(NSInteger)year;

/** Returns current date rounded to seconds. */
+(nonnull instancetype)integerDate;

/** Returns the day in month. */
-(NSInteger)day;

/** Returns whether the date is within months. Months is a bitfield, where 0x1 is January, and so on. */
-(BOOL)isWithinMonths:(NSUInteger)months;

/** Returns whether the date is within the year. */
-(BOOL)isWithinYear:(NSUInteger)year;

/** Returns the date's hour. */
-(NSInteger)hour;

/** Returns the date's minute. */
-(NSInteger)minute;

/** Returns the date's month. */
-(NSInteger)month;

/** Returns the date's second. */
-(NSInteger)second;

/** Returns the date's short description. */
-(nonnull NSString *)shortDescription;

/** Returns the date's short description, European style, day being first. */
-(nonnull NSString *)shortEuropeanDescription;

/** Returns the date's year. */
-(NSInteger)year;


/** Returns YES if the date is in future. */
@property (readonly, nonatomic, getter=isFuture) BOOL future;

/** Returns YES if the date is in past. */
@property (readonly, nonatomic, getter=isPast) BOOL past;

@end

