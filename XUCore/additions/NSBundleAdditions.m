// 
// NSBundleAdditions.m
// 
// Created by Charlie Monroe
// 
// Copyright (c) 2010-13 Fuel Collective, LLC. All rights reserved.
// 


#import "NSBundleAdditions.h"

NSBundle *FCCurrentBundle(NSObject *object){
	return [NSBundle bundleForClass:[object class]];
}

@implementation NSBundle (NSBundleAdditions)


@end

