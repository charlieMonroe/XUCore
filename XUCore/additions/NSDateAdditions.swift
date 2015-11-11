//
//  NSDataAdditions.swift
//  XUCore
//
//  Created by Charlie Monroe on 11/8/15.
//  Copyright © 2015 Charlie Monroe Software. All rights reserved.
//

import Foundation


public extension NSDate {
	
	public class func dateWithDay(day: Int, month: Int, year: Int) -> NSDate? {
		let components = NSDateComponents()
		components.day = day
		components.month = month
		components.year = year
		return NSCalendar.currentCalendar().dateFromComponents(components)
	}
	public class func integralDate() -> NSDate {
		let interval = floor(NSDate().timeIntervalSince1970)
		return NSDate(timeIntervalSince1970: interval)
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


