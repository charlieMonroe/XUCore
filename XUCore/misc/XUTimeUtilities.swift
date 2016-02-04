//
//  FCTimeUtilities.swift
//  XUCore
//
//  Created by Charlie Monroe on 11/5/15.
//  Copyright © 2015 Charlie Monroe Software. All rights reserved.
//

import Cocoa

/// Direction of the rounding
@objc public enum XUTimeRoundingDirection: Int {
	/// Floor
	case Floor = 0
	
	/// Nearest
	case Nearest = 1
	
	/// Ceiling
	case Ceiling = 2
}

/// Rounds time to certain second count. E.g. by setting seconds to 30, it will
/// round the time to 5 minutes.
public func XURoundTime(time: NSTimeInterval, direction: XUTimeRoundingDirection, seconds: UInt) -> NSTimeInterval {
	var t = UInt64(time)
	
	let remains = t % UInt64(seconds)
	if remains == 0 {
		// Keep it
		return time
	}
	
	if direction == .Floor || (direction == .Nearest && (remains < UInt64(seconds / 2))) {
		t -= remains
	}else{
		t += (UInt64(seconds) - remains)
	}
	
	return NSTimeInterval(t)
}
