//
//  _XUCoreLoader.m
//  XUCore
//
//  Created by Charlie Monroe on 11/21/15.
//  Copyright © 2015 Charlie Monroe Software. All rights reserved.
//

#import "_XUCoreLoader.h"
#import <XUCore/XUCore-Swift.h>

@implementation _XUCoreLoader

+(void)load{
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		[_XUSwiftCoreLoader loadSingletons];
	});
}

@end
