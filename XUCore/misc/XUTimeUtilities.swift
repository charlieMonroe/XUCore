//
//  FCTimeUtilities.swift
//  XUCore
//
//  Created by Charlie Monroe on 11/5/15.
//  Copyright © 2015 Charlie Monroe Software. All rights reserved.
//

import Foundation

/// Direction of the rounding
public enum XUTimeRoundingDirection: Int {
	/// Floor
	case floor = 0
	
	/// Nearest
	case nearest = 1
	
	/// Ceiling
	case ceiling = 2
}

/// A class that contains various time-related methods.
public struct XUTime {
	
	/// Returns seconds as human-readable string. E.g. 1 hour 10 minutes 1 second.
	public static func localizedTimeString(_ seconds: TimeInterval) -> String {
		
		if seconds < 0 || !seconds.isFinite || TimeInterval(Int64.max) < seconds {
			return XULocalizedString("1 second", inBundle: .core)
		}
		
		var hourString = ""
		var minuteString = ""
		var secondsString = ""
		
		var eta = Int64(seconds)
		if eta > 3599 {
			// i.e. at least one hour
			let hours = eta / 3600
			if hours == 1 {
				hourString = XULocalizedString("1 hour", inBundle: .core)
			} else {
				hourString = XULocalizedFormattedString("%li hours", hours, inBundle: .core)
			}
		}
		
		eta %= 3600;
		
		if eta > 60 {
			let minutes = eta / 60
			if minutes == 1 {
				minuteString = XULocalizedString("1 minute", inBundle: .core)
			} else {
				minuteString = XULocalizedFormattedString("%li minutes", minutes, inBundle: .core)
			}
		}
		
		eta %= 60
		
		if eta > 0 {
			if eta == 1 {
				secondsString = XULocalizedString("1 second", inBundle: .core)
			} else {
				secondsString = XULocalizedFormattedString("%li seconds", eta, inBundle: .core)
			}
		}
		
		var composedString = "\(hourString) \(minuteString) \(secondsString)"
		composedString = composedString.replacingOccurrences(of: "  ", with: " ").trimmingWhitespace
		
		return composedString

	}

	/// Rounds time to certain second count. E.g. by setting seconds to 30, it
	/// will round the time to 5 minutes.
	public static func round(time: TimeInterval, inDirection direction: XUTimeRoundingDirection, roundingBase seconds: Int) -> TimeInterval {
		if seconds < 0 || !time.isFinite || TimeInterval(Int64.max) < time {
			return 0.0
		}
		
		var t = UInt64(time)
		
		let remains = t % UInt64(seconds)
		if remains == 0 {
			// Keep it
			return time
		}
		
		if direction == .floor || (direction == .nearest && (remains < UInt64(seconds / 2))) {
			t -= remains
		}else{
			t += (UInt64(seconds) - remains)
		}
		
		return TimeInterval(t)
	}
	
	/// Converts the seconds to a time string (00:00:00 format).
	///
	/// - Parameter seconds - The time in seconds.
	/// - Parameter skipHours - If the time is < 1 hour, only includes minutes 
	///							and seconds. True by default.
	/// - Parameter includeMilliseconds - if true, then milliseconds will be included - 00:00:00.00
	/// - Parameter millisecondsBase - by default 100, you can also use 1000, other values are ignored.
	public static func timeString(from seconds: TimeInterval, skipHoursWhenZero skipHours: Bool = true, includeMilliseconds: Bool = false, millisecondsBase: Int = 100) -> String {
		if seconds < 0 || !seconds.isFinite || TimeInterval(Int64.max) < seconds {
			return "00:00"
		}
		
		var trueBase = millisecondsBase
		if trueBase != 100, trueBase != 1000 {
			trueBase = 100
		}
		
		let milliseconds = Int64(seconds.truncatingRemainder(dividingBy: 1.0) * TimeInterval(trueBase))

		var timeCp = Int64(seconds)
		
		var hours: Int64 = 0
		var minutes: Int64 = 0
		var seconds: Int64 = 0
		
		seconds = timeCp % 60
		timeCp -= seconds
		
		minutes = (timeCp % 3600) / 60
		timeCp -= minutes * 60
		
		hours = timeCp / 3600
		
		if hours == 0, skipHours {
			// Skip hours
			if includeMilliseconds {
				return String(format: "%02li:%02li.%\(trueBase == 100 ? "02" : "03")li", minutes, seconds, milliseconds)
			} else {
				return String(format: "%02li:%02li", minutes, seconds)
			}
		}
		
		if includeMilliseconds {
			return String(format: "%02li:%02li:%02li.%\(trueBase == 100 ? "02" : "03")li", hours, minutes, seconds, milliseconds)
		} else {
			return String(format: "%02li:%02li:%02li", hours, minutes, seconds)
		}
	}
	
	private static let _timeRegex: XURegex = XURegex(pattern: "^(((?P<H>\\d+):)?((?P<M>\\d+):))?(?P<S>\\d+)(\\.(?P<MS>\\d+))?$", andOptions: .caseless)
	
	/// This is the invert function of timeString(from:). Assuming that the string matches the regex
	/// \d+:\d+:\d+.\d+ (hours and minutes can be omitted), this method will convert the time to a time
	/// interval. If it doesn't match, 0 is returned.
	public static func time(from timeString: String) -> TimeInterval {
		guard let variables = _timeRegex.allVariables(in: timeString) else {
			return 0.0
		}
		
		var time = 0.0
		if let hours = variables["H"]?.doubleValue {
			time += hours * 3600.0
		}
		if let minutes = variables["M"]?.doubleValue {
			time += minutes * 60.0
		}
		if let seconds = variables["S"]?.doubleValue {
			time += seconds
		}
		if let miliseconds = variables["MS"]?.doubleValue {
			time += (miliseconds / 1000.0)
		}
		
		return time
	}
	
}
