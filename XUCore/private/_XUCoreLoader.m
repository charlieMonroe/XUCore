//
//  _XUCoreLoader.m
//  XUCore
//
//  Created by Charlie Monroe on 11/21/15.
//  Copyright © 2015 Charlie Monroe Software. All rights reserved.
//

#import "_XUCoreLoader.h"

#if TARGET_OS_IPHONE
	#import <XUCoreMobile/XUCoreMobile-Swift.h>
#else
	#import <XUCore/XUCore-Swift.h>
#endif

@implementation _XUCoreLoader

+(void)load{
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		// First, load the application setup.
		[XUApplicationSetup sharedSetup];
		
		// Launch the message center.
		[XUMessageCenter sharedMessageCenter];
		
#if !TARGET_OS_IOS
		// Start catching exceptions.
		[XUExceptionCatcher startExceptionCatcher];
		
		// Start the trial.
		[XUTrial sharedTrial];
#endif
	});
}

@end
