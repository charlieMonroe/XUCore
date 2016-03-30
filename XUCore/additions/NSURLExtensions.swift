//
//  NSURLExtensions.swift
//  XUCore
//
//  Created by Charlie Monroe on 10/29/15.
//  Copyright © 2015 Charlie Monroe Software. All rights reserved.
//

import Foundation

public extension NSURL {

	private func _booleanResourceValueForKey(key: String, defaultValue: Bool = false) -> Bool {
		var value: AnyObject?
		_ = try? self.getResourceValue(&value, forKey: key)

		guard let number = value as? NSNumber else {
			return defaultValue // Fallback to defaultValue
		}

		return number.boolValue
	}

	private func _setBooleanResourceValue(value: Bool, forKey key: String) {
		_ = try? self.setResourceValue(value, forKey: key)
	}

	/// Returns the file size.
	public var fileSize: Int {
		var value: AnyObject?
		_ = try? self.getResourceValue(&value, forKey: NSURLFileSizeKey)

		guard let number = value as? NSNumber else {
			return 0 // Fallback to 0
		}

		return number.integerValue
	}

	/// Returns true if the current URL is a directory.
	public var isDirectory: Bool {
		return self._booleanResourceValueForKey(NSURLIsDirectoryKey)
	}

	/// Returns true if the current URL is a directory.
	public var isExcludedFromBackup: Bool {
		get {
			return self._booleanResourceValueForKey(NSURLIsExcludedFromBackupKey)
		}
		set {
			self._setBooleanResourceValue(newValue, forKey: NSURLIsExcludedFromBackupKey)
		}
	}

	/// Returns true if the URL is writable.
	public var isWritable: Bool {
		return _booleanResourceValueForKey(NSURLIsWritableKey)
	}

	public var modificationDate: NSDate? {
		var value: AnyObject?
		_ = try? self.getResourceValue(&value, forKey: NSURLContentModificationDateKey)

		return value as? NSDate
	}

	public var queryDictionary: [String: String] {
		var dict: [String: String] = [:]
		for part in(self.query ?? "").componentsSeparatedByString("&") {
			let nameValParts = part.componentsSeparatedByString("=")
			let name = nameValParts[0].stringByRemovingPercentEncoding ?? ""
			let value: String
			if nameValParts.count < 2 {
				value = ""
			} else {
				value = nameValParts[1].stringByRemovingPercentEncoding ?? ""
			}

			dict[name] = value
		}

		return dict
	}

	#if os(OSX)
		public var thumbnailImage: XUImage? {
			var value: AnyObject?
			_ = try? self.getResourceValue(&value, forKey: NSURLThumbnailKey)
			return value as? XUImage
		}
	#endif

	/// Returns URL with deleted fragment (i.e. the # part). Fallbacks to self.
	public var URLByDeletingFragment: NSURL {
		if self.fragment == nil {
			return self
		}

		guard let URLComponents = NSURLComponents(URL: self, resolvingAgainstBaseURL: true) else {
			return self
		}

		URLComponents.fragment = nil

		return URLComponents.URL ?? self
	}
}

