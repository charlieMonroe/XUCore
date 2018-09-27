//
//  FCAppScopeBookmarksManager.swift
//  XUCore
//
//  Created by Charlie Monroe on 11/11/15.
//  Copyright © 2015 Charlie Monroe Software. All rights reserved.
//

import Foundation

/// A class that handles managing appscope bookmarks - which is a fancy way of
/// saving URL file references between launches.
public final class XUAppScopeBookmarksManager {
	
	public static var shared = XUAppScopeBookmarksManager()

	private var _cache: [XUPreferences.Key : URL] = [ : ]
	
	/// Sets a URL for key. Returns if the save was successful. Note that previously
	/// you could set nil and thus remove the URL for a particular key. This is
	/// no longer possible. Use removeURL(forKey:) instead.
	@discardableResult
	public func setURL(_ url: URL, forKey defaultsKey: XUPreferences.Key) -> Bool {
		var newURL = url

		// Make sure the path is different from the current one -> otherwise
		// we probably haven't opened the open dialog -> will fail
		if let savedURL = self.url(forKey: defaultsKey), savedURL == url {
			return true // Already saved.
		}
		
		#if os(iOS)
			XUPreferences.shared.perform(andSynchronize: { (prefs) in
				prefs.set(value: url.absoluteString, forKey: defaultsKey)
			})
		#else
			_ = newURL.startAccessingSecurityScopedResource()
			
			guard let bookmarkData = try? newURL.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: [], relativeTo: nil) else {
				XULog("Failed to create bookmark data for URL \(newURL)")
				return false
			}
			
			XULog("Saving bookmark data for path \(newURL.path) - bookmark data length = \(bookmarkData.count)")
			
			XUPreferences.shared.perform(andSynchronize: { (prefs) in
				prefs.set(value: bookmarkData, forKey: defaultsKey)
			})
			
			newURL.stopAccessingSecurityScopedResource()
			
			var isStale: Bool = false
			do {
				newURL = try URL(resolvingBookmarkData: bookmarkData, options: .withSecurityScope, relativeTo: nil, bookmarkDataIsStale: &isStale)
			} catch _ { }
		#endif
		
		_cache[defaultsKey] = newURL
		return true
	}
	
	/// Removes a URL for key.
	public func removeURL(forKey defaultsKey: XUPreferences.Key) {
		_cache.removeValue(forKey: defaultsKey)
		
		XUPreferences.shared.perform(andSynchronize: { (prefs) in
			prefs.set(value: nil, forKey: defaultsKey)
		})
	}
	
	/// Returns URL for key.
	public func url(forKey defaultsKey: XUPreferences.Key) -> URL? {
		if let result = _cache[defaultsKey] {
			return result
		}
		
		let result: URL?
		#if os(iOS)
			guard let absoluteURLString: String = XUPreferences.shared.value(for: defaultsKey) else {
				return nil
			}
			result = URL(string: absoluteURLString)
		#else
			guard let bookmarkData: Data = XUPreferences.shared.value(for: defaultsKey) else {
				return nil
			}
		
			do {
				var isStale: Bool = false
				result = try URL(resolvingBookmarkData: bookmarkData, options: .withSecurityScope, relativeTo: nil, bookmarkDataIsStale: &isStale)
			} catch let error {
				XULog("Failed to resolve bookmark data for \(defaultsKey) - error \(error).")
				result = nil
			}
			
			XULog("Resolved bookmark data (length: \(bookmarkData.count)) to \(result.descriptionWithDefaultValue())")
		#endif
		
		if result != nil {
			_cache[defaultsKey] = result
		}
		
		return result
	}
	
}

