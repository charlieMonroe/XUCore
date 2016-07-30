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
		// First, load the application setup.
		[XUApplicationSetup sharedSetup];
		
		// Launch the message center.
		[XUMessageCenter sharedMessageCenter];
		
		
#if !TARGET_OS_IOS
		// Start catching exceptions.
		[XUExceptionHandler startExceptionHandler];
		
		// Launch the beta expiration handler if supported.
		if ([[XUApplicationSetup sharedSetup] isBetaBuild]) {
			[XUBetaExpirationHandler sharedExpirationHandler];
		}else{
			// Start the trial.
			[XUTrial sharedTrial];
		}
#endif
	});
}

@end
