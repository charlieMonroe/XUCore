//
//  NSURLExtensions.swift
//  XUCore
//
//  Created by Charlie Monroe on 10/29/15.
//  Copyright © 2015 Charlie Monroe Software. All rights reserved.
//

import Foundation

public extension URL {

	fileprivate func _booleanResourceValue(forKey key: String, defaultValue: Bool = false) -> Bool {
		var value: AnyObject?
		_ = try? (self as NSURL).getResourceValue(&value, forKey: URLResourceKey(rawValue: key))

		guard let number = value as? NSNumber else {
			return defaultValue // Fallback to defaultValue
		}

		return number.boolValue
	}

	fileprivate func _resourceValue<T>(forKey key: String) -> T? {
		var value: AnyObject?
		_ = try? (self as NSURL).getResourceValue(&value, forKey: URLResourceKey(rawValue: key))
		return value as? T
	}
	
	fileprivate func _setBooleanResourceValue(_ value: Bool, forKey key: String) {
		_ = try? (self as NSURL).setResourceValue(value, forKey: URLResourceKey(rawValue: key))
	}
	
	fileprivate func _setResourceValue(_ value: AnyObject?, forKey key: String) {
		_ = try? (self as NSURL).setResourceValue(value, forKey: URLResourceKey(rawValue: key))
	}
	
	/// Date the URL was created at.
	public var creationDate: Date? {
		get {
			return self._resourceValue(forKey: URLResourceKey.creationDateKey.rawValue)
		}
		set {
			self._setResourceValue(newValue as AnyObject?, forKey: URLResourceKey.creationDateKey.rawValue)
		}
	}

	/// Returns the file size.
	public var fileSize: Int {
		var value: AnyObject?
		_ = try? (self as NSURL).getResourceValue(&value, forKey: URLResourceKey.fileSizeKey)

		guard let number = value as? NSNumber else {
			return 0 // Fallback to 0
		}

		return number.intValue
	}

	/// Returns true if the current URL is a directory.
	public var isDirectory: Bool {
		return self._booleanResourceValue(forKey: URLResourceKey.isDirectoryKey.rawValue)
	}

	/// Returns true if the current URL is a directory.
	public var isExcludedFromBackup: Bool {
		get {
			return self._booleanResourceValue(forKey: URLResourceKey.isExcludedFromBackupKey.rawValue)
		}
		set {
			self._setBooleanResourceValue(newValue, forKey: URLResourceKey.isExcludedFromBackupKey.rawValue)
		}
	}

	/// Returns true if the URL is writable.
	public var isWritable: Bool {
		return _booleanResourceValue(forKey: URLResourceKey.isWritableKey.rawValue)
	}

	/// Modification date of the URL. Uses NSURLContentModificationDateKey.
	public var modificationDate: Date? {
		get {
			return self._resourceValue(forKey: URLResourceKey.contentModificationDateKey.rawValue)
		}
		set {
			self._setResourceValue(newValue as AnyObject?, forKey: URLResourceKey.contentModificationDateKey.rawValue)
		}
	}

	/// If the URL has a query part, returns a dictionary of the query. Otherwise
	/// an empty dictionary.
	public var queryDictionary: [String: String] {
		var dict: [String: String] = [:]
		for part in(self.query ?? "").components(separatedBy: "&") {
			let nameValParts = part.components(separatedBy: "=")
			let name = nameValParts[0].removingPercentEncoding ?? ""
			let value: String
			if nameValParts.count < 2 {
				value = ""
			} else {
				value = nameValParts[1].removingPercentEncoding ?? ""
			}

			dict[name] = value
		}

		return dict
	}

	#if os(OSX)
		/// Thumbnail image for supported files.
		public var thumbnailImage: XUImage? {
			return self._resourceValue(forKey: URLResourceKey.thumbnailKey.rawValue)
		}
	#endif

	/// Returns URL with deleted fragment (i.e. the # part). Fallbacks to self.
	public var deletingFragment: URL {
		if self.fragment == nil {
			return self
		}

		guard var urlComponents = URLComponents(url: self, resolvingAgainstBaseURL: true) else {
			return self
		}

		urlComponents.fragment = nil

		return urlComponents.url ?? self
	}
	
	/// Returns URL with deleted query (i.e. the ? part). Fallbacks to self.
	public var deletingQuery: URL {
		if self.query == nil {
			return self
		}
		
		guard var urlComponents = URLComponents(url: self, resolvingAgainstBaseURL: true) else {
			return self
		}
		
		urlComponents.query = nil
		
		return urlComponents.url ?? self
	}
	
	/// Returns URL with replaced query (i.e. the ? part). Fallbacks to self.
	public func appendingQuery(_ query: XUJSONDictionary) -> URL {
		guard var urlComponents = URLComponents(url: self, resolvingAgainstBaseURL: true) else {
			return self
		}
		
		urlComponents.query = query.urlQueryString
		
		guard let result = urlComponents.url else {
			fatalError("Setting query from dictionary rendered invalid. This should not happen.")
		}
		
		return result
	}
}

