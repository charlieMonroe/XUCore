//
//  XUPowerAssertion.swift
//  XUCore
//
//  Created by Charlie Monroe on 11/21/15.
//  Copyright © 2015 Charlie Monroe Software. All rights reserved.
//

import Foundation
import IOKit.pwr_mgt

public func ==(lhs: XUPowerAssertion, rhs: XUPowerAssertion) -> Bool {
	return lhs.__assertionID == rhs.__assertionID && lhs.context === rhs.context && lhs.name == rhs.name
}

/// Represents a power assertion which allows you to prevent the computer from
/// going to sleep, etc.
///
/// Currently, doesn't allow you to define the type of assertion, prevents computer
/// from going to sleep by default.
open class XUPowerAssertion: Equatable {
	
	fileprivate let __assertionID: IOPMAssertionID
	
	/// You can optionally store some context reference here.
	open weak var context: AnyObject?
	
	/// Name of the assertion
	open let name: String
	
	/// If timeout is non-zero, the power assertion is released automatically
	/// after this period of time.
	open let timeout: TimeInterval
	
	
	/// Calls the designated initializer with 0 timeout.
	public convenience init?(name: String) {
		self.init(name: name, andTimeOut: 0.0)
	}
	
	/// Creates a new power assertion with timeout. See timeout property for
	/// more information.
	///
	/// May return nil if the power assertion fails to be created.
	public init?(name: String, andTimeOut timeout: TimeInterval) {
		
		self.name = name
		self.timeout = timeout
		
		var assertionID: IOPMAssertionID = IOPMAssertionID(0)
		let result = IOPMAssertionCreateWithName(kIOPMAssertPreventUserIdleSystemSleep as CFString!, IOPMAssertionLevel(kIOPMAssertionLevelOn), name as CFString!, &assertionID)
		
		__assertionID = assertionID
		
		if result != kIOReturnSuccess {
			XULog("Failed to create power assertion \(name)")
			return nil
		}
		
		if timeout != 0.0 {
			IOPMAssertionSetProperty(assertionID, kIOPMAssertionTimeoutKey as CFString!, timeout as CFTypeRef!)
			IOPMAssertionSetProperty(assertionID, kIOPMAssertionTimeoutActionKey as CFString!, kIOPMAssertionTimeoutActionRelease as CFTypeRef!)
		}
	}
	
	// Stops the assertion from being active.
	open func stop() {
		if __assertionID != 0 {
			IOPMAssertionRelease(__assertionID)
		}
	}
	
}
