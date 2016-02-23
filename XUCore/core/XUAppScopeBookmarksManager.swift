//
//  FCAppScopeBookmarksManager.swift
//  XUCore
//
//  Created by Charlie Monroe on 11/11/15.
//  Copyright © 2015 Charlie Monroe Software. All rights reserved.
//

import Foundation


public class XUAppScopeBookmarksManager: NSObject {
	
	public static var sharedManager = XUAppScopeBookmarksManager()

	private var _cache: [String : NSURL] = [ : ]
	
	private override init() {
		super.init()
	}
	
	/// Sets a URL for key. Returns if the save was successful.
	public func setURL(URL: NSURL?, forKey defaultsKey: String) -> Bool {
		var newURL = URL
		if newURL == nil {
			_cache.removeValueForKey(defaultsKey)
			
			NSUserDefaults.standardUserDefaults().removeObjectForKey(defaultsKey)
		}else{
			// Make sure the path is different from the current one -> otherwise 
			// we probably haven't opened the open dialog -> will fail
			let savedURL = self.URLForKey(defaultsKey)
			if savedURL == nil || !savedURL!.isEqual(newURL!) {
				#if os(iOS)
					NSUserDefaults.standardUserDefaults().setObject(URL!.absoluteString, forKey: defaultsKey)
				#else
					newURL!.startAccessingSecurityScopedResource()
					
					guard let bookmarkData = try? newURL!.bookmarkDataWithOptions(.WithSecurityScope, includingResourceValuesForKeys: [ ], relativeToURL: nil) else {
						XULog("Failed to create bookmark data for URL \(newURL!)")
						return false
					}
					
					XULog("trying to save bookmark data for path \(newURL!.path ?? "<>") - bookmark data length = \(bookmarkData.length)")
					
					NSUserDefaults.standardUserDefaults().setObject(bookmarkData, forKey: defaultsKey)
					
					newURL!.stopAccessingSecurityScopedResource()
					
					let reloadedURL = try? NSURL(byResolvingBookmarkData: bookmarkData, options: .WithSecurityScope, relativeToURL: nil, bookmarkDataIsStale: nil)
					if reloadedURL != nil {
						newURL = reloadedURL
					}
				#endif
				
				_cache[defaultsKey] = newURL
				
				NSUserDefaults.standardUserDefaults().synchronize()
			}
		}
		
		return true
	}
	
	/// Returns URL for key.
	public func URLForKey(defaultsKey: String) -> NSURL? {
		if let result = _cache[defaultsKey] {
			return result
		}
		
		let result: NSURL?
		#if os(iOS)
			guard let absoluteURLString = NSUserDefaults.standardUserDefaults().stringForKey(defaultsKey) else {
				return nil
			}
			result = NSURL(string: absoluteURLString)
		#else
			guard let bookmarkData = NSUserDefaults.standardUserDefaults().dataForKey(defaultsKey) else {
				return nil
			}
		
			result = try? NSURL(byResolvingBookmarkData: bookmarkData, options: .WithSecurityScope, relativeToURL: nil, bookmarkDataIsStale: nil)
			XULog("resolved bookmark data (length: \(bookmarkData.length)) to \(result)")
		#endif
		
		if result != nil {
			_cache[defaultsKey] = result
		}
		
		return result
	}
	
}

