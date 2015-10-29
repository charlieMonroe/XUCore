// 
// NSOpenPanelAdditions.m
// 
// Created by Charlie Monroe
// 
// Copyright (c) 2010-13 Fuel Collective, LLC. All rights reserved.
// 


#import "NSOpenPanelAdditions.h"

@implementation NSOpenPanel (NSOpenPanelAdditions)

-(NSInteger)runModalOnMainThread{
	if ([NSThread currentThread] == [NSThread mainThread]){
		return [self runModal];
	}
	
	NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[self methodSignatureForSelector:@selector(runModal)]];
	[invocation setSelector:@selector(runModal)];
	[invocation performSelectorOnMainThread:@selector(invokeWithTarget:) withObject:self waitUntilDone:YES];
	
	void *result = NULL;
	[invocation getReturnValue:&result];
	
	return (NSInteger)result;
}

@end

