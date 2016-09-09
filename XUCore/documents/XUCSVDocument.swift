//
// XUCSVDocument.swift
// XUCore
//
// Created by Charlie Monroe on 1/3/16.
// Copyright © 2016 Charlie Monroe Software. All rights reserved.
//

import Foundation

open class XUCSVDocument {
	
	/// Column separator. "," by default.
	fileprivate var _columnSeparator: Character = Character(",")
	
	/// Array of key -> value dictionaries. Key is either header name, or a
	/// stringified number for headerless documents.
	fileprivate var _content: [[String : AnyObject]] = []
	
	/// Array of header/column names.
	fileprivate var _headerNames: [String] = []
	
	
	fileprivate func _parseString(_ csv: String) -> Bool {
		let len = csv.characters.endIndex
		var ptr = csv.characters.startIndex
		let importantChars = CharacterSet(charactersIn: "\(_columnSeparator)\"\n")
		var column = 0
		var firstLine = true
		var insideQuotes = false
		var startIndex = csv.characters.startIndex
		var dict: [String : String] = [:]
		
		// Go through the CSV file
		while ptr < len {
			let c = csv.characters[ptr]
			if !c.isMember(of: importantChars) {
				// Unimportant char -> skip
				ptr = csv.characters.index(after: ptr)
				continue
			}
			
			// It's either comma, newline or a quote
			if c == _columnSeparator {
				if insideQuotes {
					// Comma inside a quoted string -> all right
					ptr = csv.characters.index(after: ptr)
					continue
				}
				
				// It's a comma and not inside quotes -> get the string
				var field = csv.substring(with: startIndex..<ptr).trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
				if field.hasPrefix("\"") {
					// The field begins with a quote -> remove quote at the
					// beginning and at the end and replace double-quotes with
					// single quotes
					
					// Cutting the quote at the beginning
					field = field.deleting(prefix: "\"")
					
					// Cutting the quote at the end
					field = field.deleting(suffix: "\"")
					
					// Replacing all double quotes with single quotes
					field = field.replacingOccurrences(of: "\"\"", with: "\"")
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
				ptr = csv.characters.index(after: ptr)
				startIndex = ptr
			} else if c == Character("\"") {
				// It's quotes - a few possibilities:
				if insideQuotes {
					// a) next char is also quotes -> quotes don't end yet
					if ptr < csv.characters.index(before: len) && csv.characters[csv.characters.index(after: ptr)] == Character("\"") {
						ptr = csv.characters.index(ptr, offsetBy: 2)
						continue
					} else {
						// b) either end of document on the quotes end
						if ptr < csv.characters.index(before: len) {
							// End of quotes
							insideQuotes = false
							ptr = csv.characters.index(after: ptr)
						} else {
							// c) end of document
							ptr = csv.characters.index(after: ptr)
							
							var field = csv.substring(with: startIndex..<ptr).trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
							
							if field.hasPrefix("\"") {
								// The field begins with a quote -> remove quote at
								// the beginning and at the end and replace
								// double-quotes with single quotes
								
								// Cutting the quote at the beginning
								field = field.deleting(prefix: "\"")
								
								// Cutting the quote at the end
								field = field.deleting(suffix: "\"")
								
								// Replacing all double quotes with single quotes
								field = field.replacingOccurrences(of: "\"\"", with: "\"")
							}
							
							dict[_headerNames[column]] = field
							
							_content.append(dict as [String : AnyObject])
							
							dict = [ : ] // A stopper
						}
					}
				} else {
					// d) Start of quotes
					insideQuotes = true
					startIndex = ptr
					ptr = csv.characters.index(after: ptr)
				}
			} else if c == Character("\n") {
				// New line
				if insideQuotes {
					// Can be a new line inside quoted string
					ptr = csv.characters.index(after: ptr)
					continue
				}
				
				var field = csv.substring(with: startIndex..<ptr).trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
				if field.hasPrefix("\"") {
					// The field begins with a quote -> remove quote at
					// the beginning and at the end and replace
					// double-quotes with single quotes
					
					// Cutting the quote at the beginning
					field = field.deleting(prefix: "\"")
					
					// Cutting the quote at the end
					field = field.deleting(suffix: "\"")
					
					// Replacing all double quotes with single quotes
					field = field.replacingOccurrences(of: "\"\"", with: "\"")
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
					_content.append(dict as [String : AnyObject])
					dict = [ : ]
				}
				
				firstLine = false
				column = 0
				ptr = csv.characters.index(after: ptr)
				startIndex = ptr
			}
		}
		
		if !dict.isEmpty {
			// We need to add it
			_content.append(dict as [String : AnyObject])
		}
		return true
	}
	
	open func addContentItem(_ item: [String : AnyObject]) {
		_content.append(item)
	}
	
	/// Char that separates columns. ',' by default, but some files use ';' 
	/// instead.
	open var columnSeparator: Character {
		get {
			return _columnSeparator
		}
		set {
			_columnSeparator = newValue
		}
	}
	
	open var content: [[String : AnyObject]] {
		get {
			return _content
		}
		set {
			_content = newValue
		}
	}
	
	open var headerNames: [String] {
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
	
	public convenience init(fileURL: URL, headerless: Bool = false, andColumnSeparator columnSeparator: Character = Character(",")) throws {
		
		var csv = (try NSString(contentsOf: fileURL, encoding: String.Encoding.utf8.rawValue)) as String

		if headerless {
			let firstLine = csv.firstLine
			let components = firstLine.components(separatedBy: "\(columnSeparator)")
			var headerNames: [String] = [ ]
			for i in 0..<components.count {
				headerNames.append("\(i + 1)")
			}
			
			let headerLine = headerNames.joined(separator: "\(columnSeparator)")
			
			csv = headerLine + "\n\(csv)"
			
			/// A hack - it would be best to allow some kind of a preprocessor.
			csv = csv.replacingOccurrences(of: "&amp;", with: "&")
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
	
	open var stringRepresentation: String {
		let formatter = DateFormatter()
		formatter.dateFormat = "YYYY-MM-dd HH:mm:ss"
		
		var string = _headerNames.joined(separator: String(_columnSeparator))

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
					string = "\"" + string.replacingOccurrences(of: "\"", with: "\"\"") + "\""
					return string
				}
				
				if let decimal = obj as? NSDecimalNumber {
					return String(format: "%0.4f", decimal.doubleValue)
				}
				
				if let number = obj as? NSNumber {
					return "\(number.doubleValue)"
				}
				
				if let date = obj as? Date {
					return formatter.string(from: date)
				}
				
				if let dict = obj as? [String : AnyObject] {
					if dict.isEmpty {
						return ""
					} else {
						let document = XUCSVDocument(dictionaries: [dict])
						return "\"" + document.stringRepresentation.replacingOccurrences(of: "\"", with: "\"\"") + "\""
					}
				}
				
				if let arr = obj as? [[String : AnyObject]] {
					if arr.isEmpty {
						return ""
					} else {
						let document = XUCSVDocument(dictionaries: arr)
						return "\"" + document.stringRepresentation.replacingOccurrences(of: "\"", with: "\"\"") + "\""
					}
				}
				
				// Unknown value kind.
				XUThrowAbstractException()
			}).joined(separator: String(_columnSeparator))
		}).joined(separator: "\n")
		
		return string
	}
	
	open func writeToURL(_ URL: URL) throws {
		try self.stringRepresentation.write(to: URL, atomically: true, encoding: String.Encoding.utf8)
	}
	
}
