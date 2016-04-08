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

/// A class that contains various time-related methods.
public class XUTime {
	
	/// Returns seconds as human-readable string. E.g. 1 hour 10 minutes 1 second.
	public class func localizedTimeString(seconds: NSTimeInterval) -> String {
		var hourString = ""
		var minuteString = ""
		var secondsString = ""
		
		var eta = Int(seconds)
		if eta > 3599 {
			// i.e. at least one hour
			let hours = eta / 3600
			if hours == 1 {
				hourString = XULocalizedString("1 hour")
			} else {
				hourString = XULocalizedFormattedString("%li hours", hours)
			}
		}
		
		eta %= 3600;
		
		if eta > 60 {
			let minutes = eta / 60
			if minutes == 1 {
				minuteString = XULocalizedString("1 minute")
			} else {
				minuteString = XULocalizedFormattedString("%li minutes", minutes)
			}
		}
		
		eta %= 60
		
		if eta > 0 {
			if eta == 1 {
				secondsString = XULocalizedString("1 second");
			} else {
				secondsString = XULocalizedFormattedString("%li seconds", eta)
			}
		}
		
		var composedString = "\(hourString) \(minuteString) \(secondsString)"
		composedString = composedString.stringByReplacingOccurrencesOfString("  ", withString: " ").stringByTrimmingWhitespace
		
		return composedString

	}

	/// Rounds time to certain second count. E.g. by setting seconds to 30, it
	/// will round the time to 5 minutes.
	public class func roundTime(time: NSTimeInterval, direction: XUTimeRoundingDirection, roundingBase seconds: Int) -> NSTimeInterval {
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
	
	/// Converts the seconds to a time string (00:00:00 format).
	///
	/// - Parameter seconds - The time in seconds.
	/// - Parameter skipHours - If the time is < 1 hour, only includes minutes 
	///							and seconds. True by default.
 	public class func timeString(seconds: NSTimeInterval, skipHoursWhenZero skipHours: Bool = true) -> String {
		if seconds < 0 {
			return "00:00"
		}
		
		var timeCp = Int(seconds)
		
		var hours = 0
		var minutes = 0
		var seconds = 0
		
		seconds = timeCp % 60
		timeCp -= seconds
		
		minutes = (timeCp % 3600) / 60
		timeCp -= minutes * 60
		
		hours = timeCp / 3600
		
		if hours == 0 && skipHours{
			// Skip hours
			return String(format: "%02li:%02li", minutes, seconds)
		}
		
		return String(format: "%02li:%02li:%02li", hours, minutes, seconds)
	}
	
}


@available(*, deprecated, renamed="XUTime.roundTime")
public func XURoundTime(time: NSTimeInterval, direction: XUTimeRoundingDirection, seconds: UInt) -> NSTimeInterval {
	return XUTime.roundTime(time, direction: direction, roundingBase: Int(seconds))
}
