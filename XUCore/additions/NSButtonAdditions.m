// 
// NSButtonAdditions.m
// 
// Created by Charlie Monroe
// 
// Copyright (c) 2010-13 Fuel Collective, LLC. All rights reserved.
// 


#import "NSButtonAdditions.h"


@implementation NSButton (FCAdditions)
-(BOOL)stateIsOn{
	return [self state] == NSOnState;
}
-(void)setStateIsOn:(BOOL)state{
	[self setState:state?NSOnState:NSOffState];
}
@end

