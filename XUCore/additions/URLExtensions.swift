//
//  NSURLExtensions.swift
//  XUCore
//
//  Created by Charlie Monroe on 10/29/15.
//  Copyright © 2015 Charlie Monroe Software. All rights reserved.
//

import Foundation
#if os(macOS)
	import AppKit // For NSImage
#endif

extension URL {

	private func _booleanResourceValue(forKey key: URLResourceKey, defaultValue: Bool = false) -> Bool {
		guard let values = try? self.resourceValues(forKeys: Set<URLResourceKey>(arrayLiteral: key)) else {
			return defaultValue
		}
		
		guard let value = values.allValues[key] as? Bool else {
			return defaultValue
		}
		
		return value
	}

	private func _resourceValue<T>(forKey key: URLResourceKey) -> T? {
		guard let values = try? self.resourceValues(forKeys: Set<URLResourceKey>(arrayLiteral: key)) else {
			return nil
		}
		
		return values.allValues[key] as? T
	}
	
	private mutating func _setResourceValue(with block: (inout URLResourceValues) -> Void) {
		var values = URLResourceValues()
		block(&values)
		do {
			try self.setResourceValues(values)
		} catch {
			XULog("Failed to set value on \(self) - \(error).")
		}
	}
	
	/// Just like appendingPathComponent(_:), but appends several of them.
	public func appendingPathComponents(_ components: String...) -> URL {
		var result = self
		components.forEach({ result.appendPathComponent($0) })
		return result
	}
	
	/// Just like appendingPathComponent(_:), but appends several of them.
	public func appendingPathComponents(_ components: [String]) -> URL {
		var result = self
		components.forEach({ result.appendPathComponent($0) })
		return result
	}
	
	/// Date the URL was created at.
	public var creationDate: Date? {
		get {
			return self._resourceValue(forKey: .creationDateKey)
		}
		set {
			self._setResourceValue {
				$0.creationDate = newValue
			}
		}
	}

	/// Returns the file size.
	public var fileSize: Int64 {
		var value: AnyObject?
		_ = try? (self as NSURL).getResourceValue(&value, forKey: URLResourceKey.fileSizeKey)

		guard let number = value as? NSNumber else {
			return 0 // Fallback to 0
		}

		return number.int64Value
	}

	public init?(_ urlString: String) {
		self.init(string: urlString)
	}
	
	/// Returns true if the current URL is a directory.
	public var isDirectory: Bool {
		return self._booleanResourceValue(forKey: .isDirectoryKey)
	}

	/// Returns true if the current URL is a directory.
	public var isExcludedFromBackup: Bool {
		get {
			return self._booleanResourceValue(forKey: .isExcludedFromBackupKey)
		}
		set {
			self._setResourceValue {
				$0.isExcludedFromBackup = newValue
			}
		}
	}

	/// Returns true if the URL is writable.
	public var isReadable: Bool {
		return _booleanResourceValue(forKey: .isReadableKey)
	}
	
	/// Returns true if the URL is writable.
	public var isWritable: Bool {
		return _booleanResourceValue(forKey: .isWritableKey)
	}
	
	/// Returns localized name of the file resource.
	public var localizedName: String? {
		return self._resourceValue(forKey: .localizedNameKey)
	}

	/// Modification date of the URL. Uses NSURLContentModificationDateKey.
	public var modificationDate: Date? {
		get {
			return self._resourceValue(forKey: .contentModificationDateKey)
		}
		set {
			self._setResourceValue {
				$0.contentModificationDate = newValue
			}
		}
	}

	/// If the URL has a query part, returns a dictionary of the query. Otherwise
	/// an empty dictionary.
	public var queryDictionary: [String : String] {
		get {
			return (self.query ?? "").urlQueryDictionary
		}
		set {
			self = self.updatingQuery(to: newValue)
		}
	}

	#if os(macOS)
		/// Icon image for the file.
		public var iconImage: NSImage? {
			return self._resourceValue(forKey: .effectiveIconKey)
		}
	
		/// Thumbnail image for supported files.
		public var thumbnailImage: NSImage? {
			return self._resourceValue(forKey: .thumbnailKey)
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
	public func updatingQuery(to query: XUJSONDictionary) -> URL {
		guard var urlComponents = URLComponents(url: self, resolvingAgainstBaseURL: true) else {
			return self
		}
		
		urlComponents.percentEncodedQuery = query.urlQueryString
		
		guard let result = urlComponents.url else {
			XUFatalError("Setting query from dictionary rendered invalid. This should not happen.")
		}
		
		return result
	}
}

