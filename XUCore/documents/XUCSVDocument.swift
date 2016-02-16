//
// XUCSVDocument.swift
// XUCore
//
// Created by Charlie Monroe on 1/3/16.
// Copyright © 2016 Charlie Monroe Software. All rights reserved.
//

import Foundation

public class XUCSVDocument {
	
	/// Column separator. "," by default.
	private var _columnSeparator: Character = Character(",")
	
	/// Array of key -> value dictionaries. Key is either header name, or a
	/// stringified number for headerless documents.
	private var _content: [[String : AnyObject]] = []
	
	/// Array of header/column names.
	private var _headerNames: [String] = []
	
	
	private func _parseString(csv: String) -> Bool {
		let len = csv.characters.endIndex
		var ptr = csv.characters.startIndex
		let importantChars = NSCharacterSet(charactersInString: "\(_columnSeparator)\"\n")
		var column = 0
		var firstLine = true
		var insideQuotes = false
		var startIndex = csv.characters.startIndex
		var dict: [String : String] = [:]
		
		// Go through the CSV file
		while ptr < len {
			let c = csv.characters[ptr]
			if !c.isMemberOfCharacterSet(importantChars) {
				// Unimportant char -> skip
				ptr = ptr.successor()
				continue
			}
			
			// It's either comma, newline or a quote
			if c == _columnSeparator {
				if insideQuotes {
					// Comma inside a quoted string -> all right
					ptr = ptr.successor()
					continue
				}
				
				// It's a comma and not inside quotes -> get the string
				var field = csv.substringWithRange(startIndex..<ptr).stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
				if field.hasPrefix("\"") {
					// The field begins with a quote -> remove quote at the
					// beginning and at the end and replace double-quotes with
					// single quotes
					
					// Cutting the quote at the beginning
					field = field.stringByDeletingPrefix("\"")
					
					// Cutting the quote at the end
					field = field.stringByDeletingSuffix("\"")
					
					// Replacing all double quotes with single quotes
					field = field.stringByReplacingOccurrencesOfString("\"\"", withString: "\"")
				}
				
				if firstLine {
					// It's the first line -> add the field into the _headerNames array
					_headerNames.append(field)
				} else {
					// Otherwise add it to current dictionary
					if column >= 0 && column < _headerNames.count {
						// There is a header name for this column
						dict[_headerNames[column]] = field
					} else {
						// Wrong number of columns
						return false
					}
				}
				
				column += 1
				ptr = ptr.successor()
				startIndex = ptr
			} else if c == Character("\"") {
				// It's quotes - a few possibilities:
				if insideQuotes {
					// a) next char is also quotes -> quotes don't end yet
					if ptr < len.predecessor() && csv.characters[ptr.successor()] == Character("\"") {
						ptr = ptr.advancedBy(2)
						continue
					} else {
						// b) either end of document on the quotes end
						if ptr < len.predecessor() {
							// End of quotes
							insideQuotes = false
							ptr = ptr.successor()
						} else {
							// c) end of document
							ptr = ptr.successor()
							
							var field = csv.substringWithRange(startIndex..<ptr).stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
							
							if field.hasPrefix("\"") {
								// The field begins with a quote -> remove quote at
								// the beginning and at the end and replace
								// double-quotes with single quotes
								
								// Cutting the quote at the beginning
								field = field.stringByDeletingPrefix("\"")
								
								// Cutting the quote at the end
								field = field.stringByDeletingSuffix("\"")
								
								// Replacing all double quotes with single quotes
								field = field.stringByReplacingOccurrencesOfString("\"\"", withString: "\"")
							}
							
							dict[_headerNames[column]] = field
							
							_content.append(dict)
							
							dict = [ : ] // A stopper
						}
					}
				} else {
					// d) Start of quotes
					insideQuotes = true
					startIndex = ptr
					ptr = ptr.successor()
				}
			} else if c == Character("\n") {
				// New line
				if insideQuotes {
					// Can be a new line inside quoted string
					ptr = ptr.successor()
					continue
				}
				
				var field = csv.substringWithRange(startIndex..<ptr).stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
				if field.hasPrefix("\"") {
					// The field begins with a quote -> remove quote at
					// the beginning and at the end and replace
					// double-quotes with single quotes
					
					// Cutting the quote at the beginning
					field = field.stringByDeletingPrefix("\"")
					
					// Cutting the quote at the end
					field = field.stringByDeletingSuffix("\"")
					
					// Replacing all double quotes with single quotes
					field = field.stringByReplacingOccurrencesOfString("\"\"", withString: "\"")
				}
				
				if firstLine {
					// It's the first line -> add the field into the _headerNames array
					_headerNames.append(field)
				} else {
					// Otherwise add it to current dictionary
					if column >= 0 && column < _headerNames.count {
						// There is a header name for this column
						dict[_headerNames[column]] = field
					} else {
						// Wrong number of columns
						return false
					}
				}
				
				if !firstLine {
					_content.append(dict)
					dict = [ : ]
				}
				
				firstLine = false
				column = 0
				ptr = ptr.successor()
				startIndex = ptr
			}
		}
		
		if !dict.isEmpty {
			// We need to add it
			_content.append(dict)
		}
		return true
	}
	
	public func addContentItem(item: [String : AnyObject]) {
		_content.append(item)
	}
	
	/// Char that separates columns. ',' by default, but some files use ';' 
	/// instead.
	public var columnSeparator: Character {
		get {
			return _columnSeparator
		}
		set {
			_columnSeparator = newValue
		}
	}
	
	public var content: [[String : AnyObject]] {
		get {
			return _content
		}
		set {
			_content = newValue
		}
	}
	
	public var headerNames: [String] {
		get {
			return _headerNames
		}
		set {
			_headerNames = newValue
		}
	}
	
	public init(dictionaries: [[String : AnyObject]]) {
		_content = dictionaries

		for dict in dictionaries {
			for key in dict.keys {
				if !_headerNames.contains(key) {
					_headerNames.append(key)
				}
			}
		}
	}
	
	public convenience init(fileURL: NSURL, headerless: Bool = false, andColumnSeparator columnSeparator: Character = Character(",")) throws {
		
		var csv = (try NSString(contentsOfURL: fileURL, encoding: NSUTF8StringEncoding)) as String

		if headerless {
			let firstLine = csv.firstLine
			let components = firstLine.componentsSeparatedByString("\(columnSeparator)")
			var headerNames: [String] = [ ]
			for i in 0..<components.count {
				headerNames.append("\(i + 1)")
			}
			
			let headerLine = headerNames.joinWithSeparator("\(columnSeparator)")
			
			csv = headerLine + "\n\(csv)"
			
			/// A hack - it would be best to allow some kind of a preprocessor.
			csv = csv.stringByReplacingOccurrencesOfString("&amp;", withString: "&")
		}
		
		try self.init(string: csv, andColumnSeparator: columnSeparator)
	}
	
	public init(string: String, andColumnSeparator columnSeparator: Character = Character(",")) throws {
		_columnSeparator = columnSeparator
		
		if !self._parseString(string) {
			// Could not parse string
			throw NSError(domain: NSCocoaErrorDomain, code: 0, userInfo: [
				NSLocalizedFailureReasonErrorKey: XULocalizedString("Failed to parse CSV file.", inBundle: XUCoreBundle)
			])
		}
	}
	
	public var stringRepresentation: String {
		let formatter = NSDateFormatter()
		formatter.dateFormat = "YYYY-MM-dd HH:mm:ss"
		
		var string = _headerNames.joinWithSeparator(String(_columnSeparator))

		// New line
		string += "\n"
		
		// Add all items in content
		string += _content.map({ (item) -> String in
			
			return _headerNames.map({ (headerName) -> String in
				// Adding a quoted string with replaced quotes as double-quotes
				guard let obj = item[headerName] else {
					return ""
				}
				
				if var string = obj as? String {
					string = "\"" + string.stringByReplacingOccurrencesOfString("\"", withString: "\"\"") + "\""
					return string
				}
				
				if let decimal = obj as? NSDecimalNumber {
					return String(format: "%0.4f", decimal.doubleValue)
				}
				
				if let number = obj as? NSNumber {
					return "\(number.doubleValue)"
				}
				
				if let date = obj as? NSDate {
					return formatter.stringFromDate(date)
				}
				
				if let dict = obj as? [String : AnyObject] {
					if dict.isEmpty {
						return ""
					} else {
						let document = XUCSVDocument(dictionaries: [dict])
						return "\"" + document.stringRepresentation.stringByReplacingOccurrencesOfString("\"", withString: "\"\"") + "\""
					}
				}
				
				if let arr = obj as? [[String : AnyObject]] {
					if arr.isEmpty {
						return ""
					} else {
						let document = XUCSVDocument(dictionaries: arr)
						return "\"" + document.stringRepresentation.stringByReplacingOccurrencesOfString("\"", withString: "\"\"") + "\""
					}
				}
				
				// Unknown value kind.
				XUThrowAbstractException()
			}).joinWithSeparator(String(_columnSeparator))
		}).joinWithSeparator("\n")
		
		return string
	}
	
	public func writeToURL(URL: NSURL) throws {
		try self.stringRepresentation.writeToURL(URL, atomically: true, encoding: NSUTF8StringEncoding)
	}
	
}
