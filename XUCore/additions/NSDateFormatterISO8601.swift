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
	case WithTime
	
	/// The date is formatted as day - month - year only.
	case WithoutTime
}

public extension NSDateFormatter {
	
	private static var _ISO8601Formatter: NSDateFormatter = {
		let dateFormatter = NSDateFormatter()
		dateFormatter.lenient = true
		dateFormatter.timeZone = NSTimeZone(name: "UTC")
		dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
		dateFormatter.AMSymbol = ""
		dateFormatter.PMSymbol = ""
		
		let formatterLocale = NSLocale(localeIdentifier: "en_GB")
		dateFormatter.locale = formatterLocale
		return dateFormatter
	}()
	
	private static var _ISO8601FormatterWithoutTime: NSDateFormatter = {
		let dateFormatter = NSDateFormatter()
		dateFormatter.dateFormat = "yyyy-MM-dd"
		return dateFormatter
	}()
	
	private static var _isMonthBeforeDayInDateFormat: Bool = {
		let formatter = NSDateFormatter()
		formatter.timeStyle = .NoStyle
		formatter.dateStyle = .ShortStyle
		let formattedDate = formatter.stringFromDate(NSDate.dateWithDay(4, month: 5, andYear: 1999)!)
		return formattedDate.rangeOfString("5")!.startIndex < formattedDate.rangeOfString("4")!.startIndex
	}()
	
	/// Returns true if the current locale places the month before day.
	public static var isMonthBeforeDayInDateFormat: Bool {
		get {
			return NSDateFormatter._isMonthBeforeDayInDateFormat
		}
	}
	
}

public extension NSDate {
	
	/// Tries to parse the string as an ISO 8601 string.
	public class func dateWithISO8601String(string: String, andReturnError error: AutoreleasingUnsafeMutablePointer<NSString?>) -> NSDate? {
		var date: AnyObject?
		if !NSDateFormatter._ISO8601Formatter.getObjectValue(&date, forString: string, errorDescription: error) {
			NSDateFormatter._ISO8601FormatterWithoutTime.getObjectValue(&date, forString: string, errorDescription: error)
		}
		
		return date as? NSDate
	}
	
	/// Returns a formatted string with options.
	func ISO8601FormattedStringWithOptions(options: XUISO8601Option) -> String {
		switch options {
			case .WithoutTime:
				return NSDateFormatter._ISO8601FormatterWithoutTime.stringFromDate(self)
			case .WithTime:
				return NSDateFormatter._ISO8601Formatter.stringFromDate(self)
		}
	}
	
}

