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

/// Struct containing some minor stuff around the framework itself.
public struct XUCoreFramework {
	
	/// Contains NSBundle of XUCore(Mobile) framework.
	public static let bundle = Bundle(for: _XUSwiftCoreLoader.self)
	
}

/// Private class that loads all the singletons in XUCore. This is called by 
/// _XUCoreLoader which implements +load which is not available in Swift. We need,
/// however, the loader to be in Swift since not all classes are NSObject-based
/// anymore.
@objc public class _XUSwiftCoreLoader: NSObject {
	
	private static var _didLoad: Bool = false
	
	@objc public final class func loadSingletons() {
		guard !_didLoad else {
			fatalError("Calling _XUSwiftCoreLoader for the second time.")
		}
		
		_didLoad = true
		
		// First, load the application setup.
		_ = XUApplicationSetup.shared
		
		// Launch the message center.
		_ = XUMessageCenter.shared
		
		
		#if !os(iOS)
			// Start catching exceptions.
			XUExceptionHandler.startExceptionHandler()
			
			// Launch the beta expiration handler if supported.
			if XUAppSetup.isBetaBuild {
				_ = XUBetaExpirationHandler.shared
			} else {
				// Start the trial.
				_ = XUTrial.shared
			}
		#endif
	}
	
}
