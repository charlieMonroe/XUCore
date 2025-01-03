//
//  XURegexCache.swift
//  XUCore
//
//  Created by Charlie Monroe on 12/6/24.
//  Copyright © 2024 Charlie Monroe Software. All rights reserved.
//

import Foundation

extension XURegexOptions: Hashable {
	
}

public final class XURegexCache {
	
	struct RegexKey: Hashable {
		let pattern: String
		let options: XURegexOptions
	}
	
	struct RegexCacheEntry {
		let regex: XURegex
		var counter: Int = 0
		var timestamp: TimeInterval = 0.0
	}
	
	
	public static func regex(for pattern: String, options: XURegexOptions) -> XURegex {
		return self.shared.regex(for: pattern, options: options)
	}
	
	public static let shared: XURegexCache = XURegexCache()
	
	private let _lock: XUUnfairLock = XUUnfairLock()
	
	private var _cache: [RegexKey : RegexCacheEntry] = [:]
	
	func regex(for pattern: String, options: XURegexOptions) -> XURegex {
		_lock.perform {
			let key = RegexKey(pattern: pattern, options: options)
			if _cache[key] == nil {
				_cache[key] = RegexCacheEntry(regex: XURegex(pattern: pattern, andOptions: options))
			}
			_cache[key]!.counter += 1
			_cache[key]!.timestamp = Date.timeIntervalSinceReferenceDate
			
			// Keep the cache below 50 entries.
			if _cache.count > 50, let oldestEntry = _cache.findMin({ $0.value.timestamp }) {
				_cache[oldestEntry.key] = nil
			}
			
			return _cache[key]!.regex
		}
	}
	
	public func printStatistics() {
		_lock.perform {
			let values = _cache.values.sorted(using: \.counter).reversed()
			for value in values {
				print("\(value.regex.pattern) -> \(value.counter)")
			}
		}
	}
	
	public func purge() {
		_lock.perform {
			_cache.removeAll()
		}
	}
	
}
