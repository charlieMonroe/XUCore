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
	///
	/// If `automaticallyManageSecurityScope` is set to true, then the old URL
	/// for this key will be called with `stopAccessingSecurityScopedResource()`
	/// and the new URL will be called with `startAccessingSecurityScopedResource()`.
	@discardableResult
	public func setURL(_ url: URL, forKey defaultsKey: XUPreferences.Key, automaticallyManageSecurityScope: Bool = false) -> Bool {
		var newURL = url
		
		// Make sure the path is different from the current one -> otherwise
		// we probably haven't opened the open dialog -> will fail
		if let savedURL = self.url(forKey: defaultsKey) {
			if savedURL == url {
				return true // Already saved.
			}
			
			if automaticallyManageSecurityScope {
				savedURL.stopAccessingSecurityScopedResource()
			}
		}
		
		_ = newURL.startAccessingSecurityScopedResource()
		
		let creationOptions: URL.BookmarkCreationOptions
		let resolutionOptions: URL.BookmarkResolutionOptions
		#if os(macOS)
		creationOptions = .withSecurityScope
		resolutionOptions = .withSecurityScope
		#else
		creationOptions = []
		resolutionOptions = []
		#endif
		
		let bookmarkData: Data
		do {
			bookmarkData = try newURL.bookmarkData(options: creationOptions, includingResourceValuesForKeys: [], relativeTo: nil)
		} catch {
			XULog("Failed to create bookmark data for URL \(newURL) - \(error)")
			return false
		}
		
		XULog("Saving bookmark data for path \(newURL.path) - bookmark data length = \(bookmarkData.count)")
		
		XUPreferences.shared.perform(andSynchronize: { prefs in
			prefs.set(value: bookmarkData, forKey: defaultsKey)
		})
		
		newURL.stopAccessingSecurityScopedResource()
		
		var isStale: Bool = false
		do {
			newURL = try URL(resolvingBookmarkData: bookmarkData, options: resolutionOptions, relativeTo: nil, bookmarkDataIsStale: &isStale)
		} catch _ { }
		
		if automaticallyManageSecurityScope {
			_ = newURL.startAccessingSecurityScopedResource()
		}
		
		_cache[defaultsKey] = newURL
		return true
	}
	
	/// Removes a URL for key.
	public func removeURL(forKey defaultsKey: XUPreferences.Key) {
		_cache.removeValue(forKey: defaultsKey)
		
		XUPreferences.shared.perform(andSynchronize: { prefs in
			prefs.set(value: nil, forKey: defaultsKey)
		})
	}
	
	/// Returns URL for key. If `automaticallyManageSecurityScope` is true, then upon resolving
	/// the URL, `url.startAccessingSecurityScopedResource()` is called.
	public func url(forKey defaultsKey: XUPreferences.Key, automaticallyManageSecurityScope: Bool = false) -> URL? {
		if let result = _cache[defaultsKey] {
			return result
		}
		
		let result: URL?
		guard let bookmarkData: Data = XUPreferences.shared.value(for: defaultsKey) else {
			return nil
		}
		
		let creationOptions: URL.BookmarkCreationOptions
		let resolutionOptions: URL.BookmarkResolutionOptions
		#if os(macOS)
		resolutionOptions = [.withSecurityScope, .withoutMounting]
		#else
		resolutionOptions = [.withoutMounting]
		#endif
		
		do {
			var isStale: Bool = false
			result = try URL(resolvingBookmarkData: bookmarkData, options: resolutionOptions, relativeTo: nil, bookmarkDataIsStale: &isStale)
		} catch let error {
			XULog("Failed to resolve bookmark data for \(defaultsKey) - error \(error).")
			result = nil
		}
		
		_ = result?.startAccessingSecurityScopedResource()
		
		XULog("Resolved bookmark data (length: \(bookmarkData.count)) to \(result.descriptionWithDefaultValue())")
		
		if result != nil {
			_cache[defaultsKey] = result
		}
		
		return result
	}
	
}

