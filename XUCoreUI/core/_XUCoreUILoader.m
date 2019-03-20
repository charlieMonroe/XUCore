//
//  _XUCoreUILoader.m
//  XUCoreUI
//
//  Created by Charlie Monroe on 3/20/19.
//  Copyright © 2019 Charlie Monroe Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <XUCoreUI/XUCoreUI-Swift.h>

@interface _XUCoreUILoader : NSObject

@end

@implementation _XUCoreUILoader

+(void)load {
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		[_XUSwiftCoreUILoader loadSingletons];
	});
}

@end
