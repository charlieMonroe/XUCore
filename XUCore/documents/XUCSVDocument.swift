//
// XUCSVDocument.swift
// XUCore
//
// Created by Charlie Monroe on 1/3/16.
// Copyright © 2016 Charlie Monroe Software. All rights reserved.
//

import Foundation

public final class XUCSVDocument {
	
	private func _parseString(_ csv: String) -> Bool {
		let len = csv.endIndex
		var ptr = csv.startIndex
		let newlineChars = CharacterSet.newlines
		let importantChars = CharacterSet(charactersIn: "\(self.columnSeparator)\"").union(newlineChars)
		var column = 0
		var firstLine = true
		var insideQuotes = false
		var startIndex = csv.startIndex
		var dict: [String : String] = [:]
		
		// Go through the CSV file
		while ptr < len {
			let c = csv[ptr]
			if !c.isMember(of: importantChars) {
				// Unimportant char -> skip
				ptr = csv.index(after: ptr)
				continue
			}
			
			// It's either comma, newline or a quote
			if c == self.columnSeparator {
				if insideQuotes {
					// Comma inside a quoted string -> all right
					ptr = csv.index(after: ptr)
					continue
				}
				
				// It's a comma and not inside quotes -> get the string
				var field = csv[startIndex ..< ptr].trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
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
					// It's the first line -> add the field into the self.headerNames array
					self.headerNames.append(field)
				} else {
					// Otherwise add it to current dictionary
					if column >= 0 && column < self.headerNames.count {
						// There is a header name for this column
						dict[self.headerNames[column]] = field
					} else {
						// Wrong number of columns
						return false
					}
				}
				
				column += 1
				ptr = csv.index(after: ptr)
				startIndex = ptr
			} else if c == Character("\"") {
				// It's quotes - a few possibilities:
				if insideQuotes {
					// a) next char is also quotes -> quotes don't end yet
					if ptr < csv.index(before: len) && csv[csv.index(after: ptr)] == Character("\"") {
						ptr = csv.index(ptr, offsetBy: 2)
						continue
					} else {
						// b) either end of document on the quotes end
						if ptr < csv.index(before: len) {
							// End of quotes
							insideQuotes = false
							ptr = csv.index(after: ptr)
						} else {
							// c) end of document
							ptr = csv.index(after: ptr)
							
							var field = csv[startIndex ..< ptr].trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
							
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
							
							dict[self.headerNames[column]] = field
							
							self.content.append(dict as [String : Any])
							
							dict = [ : ] // A stopper
						}
					}
				} else {
					// d) Start of quotes
					insideQuotes = true
					startIndex = ptr
					ptr = csv.index(after: ptr)
				}
			} else if c.isMember(of: newlineChars) {
				// New line
				if insideQuotes {
					// Can be a new line inside quoted string
					ptr = csv.index(after: ptr)
					continue
				}
				
				var field = csv[startIndex ..< ptr].trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
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
					// It's the first line -> add the field into the self.headerNames array
					self.headerNames.append(field)
				} else {
					// Otherwise add it to current dictionary
					if column >= 0 && column < self.headerNames.count {
						// There is a header name for this column
						dict[self.headerNames[column]] = field
					} else {
						// Wrong number of columns
						return false
					}
				}
				
				if !firstLine {
					self.content.append(dict as [String : Any])
					dict = [ : ]
				}
				
				firstLine = false
				column = 0
				ptr = csv.index(after: ptr)
				startIndex = ptr
			}
		}
		
		if !dict.isEmpty {
			// We need to add it
			self.content.append(dict as [String : Any])
		}
		return true
	}
	
	public func addContentItem(_ item: [String : Any]) {
		self.content.append(item)
	}
	
	/// Char that separates columns. ',' by default, but some files use ';' 
	/// instead.
	public var columnSeparator: Character = Character(",")
	
	/// Array of key -> value dictionaries. Key is either header name, or a
	/// stringified number for headerless documents.
	public var content: [[String : Any]] = []
	
	/// Array of header/column names.
	public var headerNames: [String] = []
	
	public init(dictionaries: [[String : Any]]) {
		self.content = dictionaries

		for dict in dictionaries {
			for key in dict.keys {
				if !self.headerNames.contains(key) {
					self.headerNames.append(key)
				}
			}
		}
	}
	
	public convenience init(fileURL: URL, headerless: Bool = false, columnSeparator: Character = Character(",")) throws {
		var csv = try String(contentsOf: fileURL, encoding: .utf8)

		if headerless {
			let firstLine = csv.firstLine
			let components = firstLine.components(separatedBy: "\(columnSeparator)")
			var headerNames: [String] = [ ]
			for i in 0 ..< components.count {
				headerNames.append("\(i + 1)")
			}
			
			let headerLine = headerNames.joined(separator: "\(columnSeparator)")
			
			csv = headerLine + "\n\(csv)"
			
			/// A hack - it would be best to allow some kind of a preprocessor.
			csv = csv.replacingOccurrences(of: "&amp;", with: "&")
		}
		
		try self.init(string: csv, columnSeparator: columnSeparator)
	}
	
	public init(string: String, columnSeparator: Character = Character(",")) throws {
		self.columnSeparator = columnSeparator
		
		if !self._parseString(string) {
			// Could not parse string
			throw NSError(domain: NSCocoaErrorDomain, code: 0, userInfo: [
				NSLocalizedFailureReasonErrorKey: XULocalizedString("Failed to parse CSV file.", inBundle: .core)
			])
		}
	}
	
	public var stringRepresentation: String {
		let formatter = DateFormatter()
		formatter.dateFormat = "YYYY-MM-dd HH:mm:ss"
		
		var string = self.headerNames.joined(separator: String(self.columnSeparator))

		// New line
		string += "\n"
		
		// Add all items in content
		string += self.content.map({ (item) -> String in
			
			return self.headerNames.map({ (headerName) -> String in
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
				
				if let dict = obj as? [String : Any] {
					if dict.isEmpty {
						return ""
					} else {
						let document = XUCSVDocument(dictionaries: [dict])
						return "\"" + document.stringRepresentation.replacingOccurrences(of: "\"", with: "\"\"") + "\""
					}
				}
				
				if let arr = obj as? [[String : Any]] {
					if arr.isEmpty {
						return ""
					} else {
						let document = XUCSVDocument(dictionaries: arr)
						return "\"" + document.stringRepresentation.replacingOccurrences(of: "\"", with: "\"\"") + "\""
					}
				}
				
				// Unknown value kind.
				XUFatalError()
			}).joined(separator: String(self.columnSeparator))
		}).joined(separator: "\n")
		
		return string
	}
	
	public func write(to url: URL) throws {
		try self.stringRepresentation.write(to: url, atomically: true, encoding: String.Encoding.utf8)
	}
	
}
