//
//  XUCoreUtils.swift
//  XUCore
//
//  Created by Charlie Monroe on 11/22/15.
//  Copyright © 2015 Charlie Monroe Software. All rights reserved.
//
//  This file contains a few methods that are meant for internal use within the
//  XUCore(Mobile) framework.
//

import Foundation

/// Private class which is needed for XUCoreBundle.
private class XUCore {
	
}

/// Contains NSBundle of XUCore(Mobile) framework.
public let XUCoreBundle = Bundle(for: XUCore.self)

/// Private class that loads all the singletons in XUCore. This is called by 
/// _XUCoreLoader which implements +load which is not available in Swift. We need,
/// however, the loader to be in Swift since not all classes are NSObject-based
/// anymore.
@objc open class _XUSwiftCoreLoader: NSObject {
	
	fileprivate static var _didLoad: Bool = false
	
	open class func loadSingletons() {
		guard !_didLoad else {
			fatalError("Calling _XUSwiftCoreLoader for the second time.")
		}
		
		_didLoad = true
		
		// First, load the application setup.
		_ = XUApplicationSetup.sharedSetup
		
		// Launch the message center.
		_ = XUMessageCenter.sharedMessageCenter
		
		
		#if !os(iOS)
			// Start catching exceptions.
			XUExceptionHandler.startExceptionHandler()
			
			// Launch the beta expiration handler if supported.
			if XUAppSetup.isBetaBuild {
				_ = XUBetaExpirationHandler.sharedExpirationHandler
			} else {
				// Start the trial.
				_ = XUTrial.sharedTrial
			}
		#endif
	}
	
}
