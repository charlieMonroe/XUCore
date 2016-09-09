//
//  NSDateFormatterISO8601.swift
//  MewsBase
//
//  Created by Charlie Monroe on 11/30/15.
//  Copyright © 2015 Charlie Monroe Software. All rights reserved.
//

import Foundation

/// Option as to how the date is formatted
@objc public enum XUISO8601Option: Int {
	
	/// The format includes time.
	case withTime
	
	/// The date is formatted as day - month - year only.
	case withoutTime
}

public extension DateFormatter {
	
	fileprivate static var _ISO8601Formatter: DateFormatter = {
		let dateFormatter = DateFormatter()
		dateFormatter.isLenient = true
		dateFormatter.timeZone = TimeZone(identifier: "UTC")
		dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
		dateFormatter.amSymbol = ""
		dateFormatter.pmSymbol = ""
		
		let formatterLocale = Locale(identifier: "en_GB")
		dateFormatter.locale = formatterLocale
		return dateFormatter
	}()
	
	fileprivate static var _ISO8601FormatterWithoutTime: DateFormatter = {
		let dateFormatter = DateFormatter()
		dateFormatter.dateFormat = "yyyy-MM-dd"
		return dateFormatter
	}()
	
	fileprivate static var _isMonthBeforeDayInDateFormat: Bool = {
		let formatter = DateFormatter()
		formatter.timeStyle = .none
		formatter.dateStyle = .short
		let formattedDate = formatter.string(from: Date.date(withDay: 4, month: 5, year: 1999)!)
		return formattedDate.range(of: "5")!.lowerBound < formattedDate.range(of: "4")!.lowerBound
	}()
	
	/// Returns true if the current locale places the month before day.
	public static var isMonthBeforeDayInDateFormat: Bool {
		get {
			return DateFormatter._isMonthBeforeDayInDateFormat
		}
	}
	
}

public extension Date {
	
	/// Tries to parse the string as an ISO 8601 string.
	public static func date(withISO8601 string: String, andReturnError error: AutoreleasingUnsafeMutablePointer<NSString?>? = nil) -> Date? {
		var date: AnyObject?
		if !DateFormatter._ISO8601Formatter.getObjectValue(&date, for: string, errorDescription: error) {
			DateFormatter._ISO8601FormatterWithoutTime.getObjectValue(&date, for: string, errorDescription: error)
		}
		
		return date as? Date
	}
	
	@available(*, deprecated, renamed: "date(withISO8601:andReturnError:)")
	public static func dateWithISO8601String(_ string: String, andReturnError error: AutoreleasingUnsafeMutablePointer<NSString?>?) -> Date? {
		return self.date(withISO8601: string, andReturnError: error)
	}
	
	/// Returns a formatted string with options.
	public func iso8601FormattedString(withOptions options: XUISO8601Option) -> String {
		switch options {
			case .withoutTime:
				return DateFormatter._ISO8601FormatterWithoutTime.string(from: self)
			case .withTime:
				return DateFormatter._ISO8601Formatter.string(from: self)
		}
	}
	
}

