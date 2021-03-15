//
//  XUCoreUIUtils.swift
//  XUCoreUI
//
//  Created by Charlie Monroe on 3/20/19.
//  Copyright © 2019 Charlie Monroe Software. All rights reserved.
//

import Foundation
import XUCore

/// Private class that loads all the singletons in XUCoreUI. This is called by
/// _XUCoreUILoader which implements +load which is not available in Swift. We need,
/// however, the loader to be in Swift since not all classes are NSObject-based
/// anymore.
@objc(_XUSwiftCoreUILoader) public class _XUSwiftCoreUILoader: NSObject {
	
	private static var _didLoad: Bool = false
	
	@objc public final class func loadSingletons() {
		guard !_didLoad else {
			XUFatalError("Calling _XUSwiftCoreUILoader for the second time.")
		}
		
		_didLoad = true
		
		// Launch the message center.
		_ = XUMessageCenter.shared
		
		// Start catching exceptions - this is being moved to DownmuteUI.
		if XUAppSetup.exceptionHandlerReportURL != nil, NSClassFromString("DownmuteUI.DMExceptionHandler") == nil {
			XULog("**************************************")
			XULog("Attempting to start deprecated exception handler!")
			XULog("Migrate to DownmuteUI.")
			XULog("**************************************")
		}
		
		// Launch the beta expiration handler if supported.
		if XUAppSetup.isBetaBuild {
			_ = XUBetaExpirationHandler.shared
		}
	}
	
}
