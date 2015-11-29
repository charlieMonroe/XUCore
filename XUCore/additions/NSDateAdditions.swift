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
			__validUntil = __today!.timeIntervalSinceReferenceDate + 24.0 * 3600.0
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
	
	public var isFuture: Bool {
		return self.timeIntervalSinceReferenceDate > NSDate.timeIntervalSinceReferenceDate()
	}
	
	public var isPast: Bool {
		return self.timeIntervalSinceReferenceDate < NSDate.timeIntervalSinceReferenceDate()
	}
	
	public func isWithinMonths(months: Int) -> Bool {
		let calendar = NSCalendar.currentCalendar()
		let components = calendar.components(.Month, fromDate: self)
		let shift = (1 << (components.month - 1))
		let result = ((shift & months) != 0)
		return result
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
	
	public var year: Int {
		let calendar = NSCalendar.currentCalendar()
		let components = calendar.components(.Year, fromDate: self)
		return components.year
		
	}
	
}


