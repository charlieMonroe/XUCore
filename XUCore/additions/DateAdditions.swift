//
//  DateAdditions.swift
//  XUCore
//
//  Created by Charlie Monroe on 11/8/15.
//  Copyright © 2015 Charlie Monroe Software. All rights reserved.
//

import Foundation

/// Used by +today
private var __today: Date?
private var __validUntil: TimeInterval = 0

/// Contains time intervals, like hour, minute, day, week. Ideally, this would
/// be TimeInterval extension. Unfortunately, TimeInterval is only a typealias
/// for Double, so Double.day would be valid as well, which we don't want.
public struct XUTimeInterval {
	
	public static let day: TimeInterval = 24.0 * 3600.0
	public static let hour: TimeInterval = 3600.0
	public static let minute: TimeInterval = 60.0
	public static let week: TimeInterval = 7.0 * 24.0 * 3600.0
	
	private init() {}
}



public struct XUMonth: OptionSet, Comparable, Equatable {
	
	public static func <(_ lhs: XUMonth, _ rhs: XUMonth) -> Bool {
		return lhs.rawValue < rhs.rawValue
	}
	
	public let rawValue: Int
	
	public init(rawValue: Int) { self.rawValue = rawValue }
	
	public static let january = XUMonth(rawValue: 1 << 0)
	public static let february = XUMonth(rawValue: 1 << 1)
	public static let march = XUMonth(rawValue: 1 << 2)
	public static let april = XUMonth(rawValue: 1 << 3)
	public static let may = XUMonth(rawValue: 1 << 4)
	public static let june = XUMonth(rawValue: 1 << 5)
	public static let july = XUMonth(rawValue: 1 << 6)
	public static let august = XUMonth(rawValue: 1 << 7)
	public static let september = XUMonth(rawValue: 1 << 8)
	public static let october = XUMonth(rawValue: 1 << 9)
	public static let november = XUMonth(rawValue: 1 << 10)
	public static let december = XUMonth(rawValue: 1 << 11)
	
	/// Contains a mask for the entire quarter.
	public static let quarter1: XUMonth = [ .january, .february, .march ]
	
	/// Contains a mask for the entire quarter.
	public static let quarter2: XUMonth = [ .april, .may, .june ]
	
	/// Contains a mask for the entire quarter.
	public static let quarter3: XUMonth = [ .july, .august, .september ]
	
	/// Contains a mask for the entire quarter.
	public static let quarter4: XUMonth = [ .october, .november, .december ]
	
	public static let allMonths: XUMonth = [
		.quarter1, .quarter2, .quarter3, .quarter4
	]
	
	/// Returns true if the current mask is a single month.
	public var isSingleMonth: Bool {
		return XUMonth.allMonthsArray.count(where: { self.contains($0) }) == 1
	}
	
	/// This will return the month integer (1-12). If the option set contains
	/// more than one month, this will call fatalError(_).
	public var month: Int {
		switch self {
		case XUMonth.january:
			return 1
		case XUMonth.february:
			return 2
		case XUMonth.march:
			return 3
		case XUMonth.april:
			return 4
		case XUMonth.may:
			return 5
		case XUMonth.june:
			return 6
		case XUMonth.july:
			return 7
		case XUMonth.august:
			return 8
		case XUMonth.september:
			return 9
		case XUMonth.october:
			return 10
		case XUMonth.november:
			return 11
		case XUMonth.december:
			return 12
			
		default:
			fatalError("Calling month on a XUMonth mask that is not a single-month.")
		}
	}
	
	/// Array of all months.
	public static let allMonthsArray: [XUMonth] = [
		.january, .february, .march, .april, .may, .june,
		.july, .august, .september, .november, .october, .december
	]
	
}


public extension Date {
	
	static func -(lhs: Date, rhs: Date) -> TimeInterval {
		return lhs.timeIntervalSinceReferenceDate - rhs.timeIntervalSinceReferenceDate
	}
		
	/// Returns today at 00:00:00.
	static var today: Date {
		if __today == nil || __validUntil <= Date.timeIntervalSinceReferenceDate {
			let date = Date()
			let calendar = Calendar.current
			__today = calendar.startOfDay(for: date)
			__validUntil = __today!.timeIntervalSinceReferenceDate + XUTimeInterval.day
		}
		return __today!
	}
	
	
	/// Converts this date to target time zone.
	func converting(from originZone: TimeZone, to targetZone: TimeZone) -> Date {
		var convertedDate = self.timeIntervalSinceReferenceDate
		convertedDate -= TimeInterval(originZone.secondsFromGMT()) - TimeInterval(targetZone.secondsFromGMT())
		return Date(timeIntervalSinceReferenceDate: convertedDate)
	}
	
	var day: Int {
		let calendar = Calendar.current
		return calendar.component(.day, from: self)
	}
	
	var hour: Int {
		let calendar = Calendar.current
		return calendar.component(.hour, from: self)
	}
	
	/// Returns date with day/month/year/hour/minute/second values, if valid.
	init?(day: Int, month: Int, year: Int, hour: Int = 0, minute: Int = 0, second: Int = 0) {
		var components = DateComponents()
		components.day = day
		components.month = month
		components.year = year
		components.hour = hour
		components.minute = minute
		components.second = second
		guard let date = Calendar.current.date(from: components) else {
			return nil
		}
		
		self = date
	}
	
	/// Returns a new date object that is rounded down to seconds.
	var integralDate: Date {
		let interval = floor(self.timeIntervalSince1970)
		return Date(timeIntervalSince1970: interval)
	}
	
	/// Returns true if the receiver is after date.
	func isAfter(_ date: Date) -> Bool {
		return date.timeIntervalSince1970 < self.timeIntervalSince1970
	}
	
	/// Returns true if the receiver is before date.
	func isBefore(_ date: Date) -> Bool {
		return self.timeIntervalSince1970 < date.timeIntervalSince1970
	}
	
	/// Returns true iff date1 < self < date2.
	func isBetween(_ date1: Date, and date2: Date) -> Bool {
		return self.isAfter(date1) && self.isBefore(date2)
	}
	
	/// Returns true if the receiver referes to an newer date than in now.
	var isFuture: Bool {
		return self.timeIntervalSinceReferenceDate > Date.timeIntervalSinceReferenceDate
	}
	
	/// Returns true if the receiver referes to an older date than in now.
	var isPast: Bool {
		return self.timeIntervalSinceReferenceDate < Date.timeIntervalSinceReferenceDate
	}
	
	/// Returns true if the receiver's day, month and year match the one of now.
	var isToday: Bool {
		let now = Date()
		return now.day == self.day && now.month == self.month && now.year == self.year
	}
	
	func isWithin(months: XUMonth) -> Bool {
		let month = XUMonth(rawValue: (1 << (self.month - 1)))
		return months.contains(month)
	}
	
	func isWithin(year: Int) -> Bool {
		return self.year == year
	}
	
	var minute: Int {
		let calendar = Calendar.current
		return calendar.component(.minute, from: self)
	}
	
	var month: Int {
		let calendar = Calendar.current
		return calendar.component(.month, from: self)
	}
	
	var second: Int {
		let calendar = Calendar.current
		return calendar.component(.second, from: self)
	}
	
	var shortDescription: String {
		let formatter = DateFormatter()
		formatter.dateStyle = .short
		formatter.timeStyle = .none
		return formatter.string(from: self)
	}
	
	var shortEuropeanDescription: String {
		return String(format: "%02i.%02i.%04i", self.day, self.month, self.year)
	}
	
	/// Returns a date that is within the same day as self, but has 0 hours,
	/// 0 minutes and 0 seconds.
	var startOfDay: Date {
		return Date(day: self.day, month: self.month, year: self.year) ?? self
	}
	
	var year: Int {
		let calendar = Calendar.current
		return calendar.component(.year, from: self)
		
	}
	
}
