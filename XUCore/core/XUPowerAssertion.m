//
//  XUPowerAssertion.m
//  Downie
//
//  Created by Charlie Monroe on 8/13/14.
//  Copyright (c) 2014 Charlie Monroe Software. All rights reserved.
//

#import "XUPowerAssertion.h"

#import <IOKit/pwr_mgt/IOPMLib.h>

#import "FCLog.h"

@implementation XUPowerAssertion {
	IOPMAssertionID __assertionID;
}

+(instancetype)powerAssertionWithName:(NSString *)name{
	return [self powerAssertionWithName:name andTimeout:0.0];
}
+(instancetype)powerAssertionWithName:(NSString *)name andTimeout:(NSTimeInterval)timeout{
	return [[self alloc] initWithName:name andTimeout:timeout];
}

-(void)dealloc{
	[self stop];
}
-(instancetype)initWithName:(NSString *)name andTimeout:(NSTimeInterval)timeout{
	if ((self = [super init]) != nil){
		_name = name;
		_timeout = timeout;
		
		if (IOPMAssertionCreateWithName(kIOPMAssertPreventUserIdleSystemSleep, kIOPMAssertionLevelOn, (__bridge CFStringRef)_name, &__assertionID) != kIOReturnSuccess){
			FCLog(@"%s - failed to create power assertion %@", __FCFUNCTION__, _name);
			self = nil;
			return nil;
		}
		
		if (_timeout != 0){
			IOPMAssertionSetProperty(__assertionID, kIOPMAssertionTimeoutKey, (__bridge CFNumberRef)@(_timeout));
			IOPMAssertionSetProperty(__assertionID, kIOPMAssertionTimeoutActionKey, kIOPMAssertionTimeoutActionRelease);
		}
	}
	return self;
}

-(void)stop{
	if (__assertionID != 0){
		IOPMAssertionRelease(__assertionID);
	}
}

@end
