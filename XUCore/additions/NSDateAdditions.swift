//
//  NSDataAdditions.swift
//  XUCore
//
//  Created by Charlie Monroe on 11/8/15.
//  Copyright © 2015 Charlie Monroe Software. All rights reserved.
//

import Foundation

/// Used by +today
private var __today: NSDate?
private var __validUntil: NSTimeInterval = 0

/// Contains time intervals, like hour, minute, day, week. Ideally, this would
/// be NSTimeInterval extension. Unfortunately, NSTimeInterval is only a typealias
/// for Double, so Double.day would be valid as well, which we don't want.
public struct XUTimeInterval {
	
	public static let day: NSTimeInterval = 24.0 * 3600.0
	public static let hour: NSTimeInterval = 3600.0
	public static let minute: NSTimeInterval = 60.0
	public static let week: NSTimeInterval = 7.0 * 24.0 * 3600.0
	
	private init() {}
}



public struct XUMonth : OptionSetType {
	public let rawValue: Int
	
	public init(rawValue: Int) { self.rawValue = rawValue }
	
	public static let January = XUMonth(rawValue: 1 << 0)
	public static let February = XUMonth(rawValue: 1 << 1)
	public static let March = XUMonth(rawValue: 1 << 2)
	public static let April = XUMonth(rawValue: 1 << 3)
	public static let May = XUMonth(rawValue: 1 << 4)
	public static let June = XUMonth(rawValue: 1 << 5)
	public static let July = XUMonth(rawValue: 1 << 6)
	public static let August = XUMonth(rawValue: 1 << 7)
	public static let September = XUMonth(rawValue: 1 << 8)
	public static let October = XUMonth(rawValue: 1 << 9)
	public static let November = XUMonth(rawValue: 1 << 10)
	public static let December = XUMonth(rawValue: 1 << 11)
	
	/// Contains a mask for the entire quarter.
	public static let Quarter1: XUMonth = [ .January, .February, .March ]
	
	/// Contains a mask for the entire quarter.
	public static let Quarter2: XUMonth = [ .April, .May, .June ]
	
	/// Contains a mask for the entire quarter.
	public static let Quarter3: XUMonth = [ .July, .August, .September ]
	
	/// Contains a mask for the entire quarter.
	public static let Quarter4: XUMonth = [ .October, .November, .December ]
	
	public static let AllMonths: XUMonth = [
		.Quarter1, .Quarter2, .Quarter3, .Quarter4
	]
	
	/// Returns true if the current mask is a single month.
	public var isSingleMonth: Bool {
		return XUMonth.AllMonthsArray.count({ self.contains($0) }) == 1
	}
	
	/// This will return the month integer (1-12). If the option set contains
	/// more than one month, this will call fatalError(_).
	public var month: Int {
		switch self {
		case XUMonth.January:
			return 1
		case XUMonth.February:
			return 2
		case XUMonth.March:
			return 3
		case XUMonth.April:
			return 4
		case XUMonth.May:
			return 5
		case XUMonth.June:
			return 6
		case XUMonth.July:
			return 7
		case XUMonth.August:
			return 8
		case XUMonth.September:
			return 9
		case XUMonth.October:
			return 10
		case XUMonth.November:
			return 11
		case XUMonth.December:
			return 12
			
		default:
			fatalError("Calling month on a XUMonth mask that is not a single-month.")
		}
	}
	
	/// Array of all months.
	public static let AllMonthsArray: [XUMonth] = [
		.January, .February, .March, .April, .May, .June,
		.July, .August, .September, .November, .October, .December
	]
	
}


public extension NSDate {
	
	/// Returns date with day/month/year values, if valid.
	///
	/// @note - cannot currently be an initializer since there is no initializer
	///			that takes NSDateComponents as an arguments
	public class func dateWithDay(day: Int, month: Int, andYear year: Int) -> NSDate? {
		return self.dateWithDay(day, month: month, year: year, hour: 0, minute: 0, andSecond: 0)
	}
	
	/// Returns date with day/month/year/hour/minute/second values, if valid.
	///
	/// @note - cannot currently be an initializer since there is no initializer
	///			that takes NSDateComponents as an arguments
	public class func dateWithDay(day: Int, month: Int, year: Int, hour: Int, minute: Int, andSecond second: Int) -> NSDate? {
		let components = NSDateComponents()
		components.day = day
		components.month = month
		components.year = year
		components.hour = hour
		components.minute = minute
		components.second = second
		return NSCalendar.currentCalendar().dateFromComponents(components)
	}
	
	/// Returns today at 00:00:00.
	public class func today() -> NSDate {
		if __today == nil || __validUntil <= NSDate.timeIntervalSinceReferenceDate() {
			let date = NSDate()
			let calendar = NSCalendar.currentCalendar()
			__today = calendar.startOfDayForDate(date)
			__validUntil = __today!.timeIntervalSinceReferenceDate + XUTimeInterval.day
		}
		return __today!
	}
	
	
	/// Converts this date to target time zone.
	public func dateByConvertingFromTimeZone(originZone: NSTimeZone, toZone targetZone: NSTimeZone) -> NSDate {
		var convertedDate = self.timeIntervalSinceReferenceDate
		convertedDate -= NSTimeInterval(originZone.secondsFromGMT) - NSTimeInterval(targetZone.secondsFromGMT)
		return NSDate(timeIntervalSinceReferenceDate: convertedDate)
	}
	
	public var day: Int {
		let calendar = NSCalendar.currentCalendar()
		let components = calendar.components(.Day, fromDate: self)
		return components.day
	}
	
	public var hour: Int {
		let calendar = NSCalendar.currentCalendar()
		let components = calendar.components(.Hour, fromDate: self)
		return components.hour
	}
	
	/// Returns a new date object that is rounded down to seconds.
	public var integralDate: NSDate {
		let interval = floor(self.timeIntervalSince1970)
		return NSDate(timeIntervalSince1970: interval)
	}
	
	/// Returns true if the receiver is after date.
	public func isAfterDate(date: NSDate) -> Bool {
		return date.timeIntervalSince1970 < self.timeIntervalSince1970
	}
	
	/// Returns true if the receiver is before date.
	public func isBeforeDate(date: NSDate) -> Bool {
		return self.timeIntervalSince1970 < date.timeIntervalSince1970
	}
	
	/// Returns true iff date1 < self < date2.
	public func isBetweenDate(date1: NSDate, andDate date2: NSDate) -> Bool {
		return self.isAfterDate(date1) && self.isBeforeDate(date2)
	}
	
	/// Returns true if the receiver referes to an newer date than in now.
	public var isFuture: Bool {
		return self.timeIntervalSinceReferenceDate > NSDate.timeIntervalSinceReferenceDate()
	}
	
	/// Returns true if the receiver referes to an older date than in now.
	public var isPast: Bool {
		return self.timeIntervalSinceReferenceDate < NSDate.timeIntervalSinceReferenceDate()
	}
	
	/// Returns true if the receiver's day, month and year match the one of now.
	public var isToday: Bool {
		let now = NSDate()
		return now.day == self.day && now.month == self.month && now.year == self.year
	}
	
	public func isWithinMonths(months: XUMonth) -> Bool {
		let calendar = NSCalendar.currentCalendar()
		let components = calendar.components(.Month, fromDate: self)
		
		let month = XUMonth(rawValue: (1 << (components.month - 1)))
		return months.contains(month)
	}
	
	public func isWithinYear(year: Int) -> Bool {
		let calendar = NSCalendar.currentCalendar()
		let components = calendar.components(.Year, fromDate: self)
		return components.year == year
	}
	
	public var minute: Int {
		let calendar = NSCalendar.currentCalendar()
		let components = calendar.components(.Minute, fromDate: self)
		return components.minute
	}
	
	public var month: Int {
		let calendar = NSCalendar.currentCalendar()
		let components = calendar.components(.Month, fromDate: self)
		return components.month
	}
	
	public var second: Int {
		let calendar = NSCalendar.currentCalendar()
		let components = calendar.components(.Second, fromDate: self)
		return components.second
	}
	
	public var shortDescription: String {
		let formatter = NSDateFormatter()
		formatter.dateStyle = .ShortStyle
		formatter.timeStyle = .NoStyle
		return formatter.stringFromDate(self)
	}
	
	public var shortEuropeanDescription: String {
		let components = NSCalendar.currentCalendar().components([ .Day, .Month, .Year ], fromDate: self)
		return String(format: "%02i.%02i.%04i", components.day, components.month, components.year)
	}
	
	/// Returns a date that is within the same day as self, but has 0 hours,
	/// 0 minutes and 0 seconds.
	public var startOfDay: NSDate {
		return NSDate.dateWithDay(self.day, month: self.month, andYear: self.year) ?? self
	}
	
	public var year: Int {
		let calendar = NSCalendar.currentCalendar()
		let components = calendar.components(.Year, fromDate: self)
		return components.year
		
	}
	
}


