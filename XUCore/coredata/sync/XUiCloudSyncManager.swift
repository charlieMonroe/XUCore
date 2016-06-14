//
//  XUiCloudSyncManager.swift
//  XUCore
//
//  Created by Charlie Monroe on 6/3/16.
//  Copyright © 2016 Charlie Monroe Software. All rights reserved.
//

import Foundation

private func _rootURLForManagerWithName(name: String) -> NSURL? {
	return NSFileManager.defaultManager().URLForUbiquityContainerIdentifier(nil)?.URLByAppendingPathComponent(name)
}

/// Manager for syncing via iCloud.
public class XUiCloudSyncManager: XUApplicationSyncManager {
	
	
	private var _rootURL: NSURL? {
		return _rootURLForManagerWithName(self.name)
	}
	
	private func _startDownloadingUbiquitousItemAtURL(URL: NSURL) {
		if URL.isDirectory {
			let contents = NSFileManager.defaultManager().contentsOfDirectoryAtURL(URL)
			for fileURL in contents {
				self._startDownloadingUbiquitousItemAtURL(fileURL)
			}
		} else {
			_ = try? NSFileManager.defaultManager().startDownloadingUbiquitousItemAtURL(URL)
		}
	}
	
	@objc private func _updateUbiquityFolderURL() {
		if let ubiquityFolderURL = NSFileManager.defaultManager().URLForUbiquityContainerIdentifier(nil)?.URLByAppendingPathComponent(self.name) {
			self.syncRootFolderURL = ubiquityFolderURL
			self._startDownloadingUbiquitousItemAtURL(ubiquityFolderURL)
		}
	}
	
	public init(name: String, andDelegate delegate: XUApplicationSyncManagerDelegate) {
		super.init(name: name, rootFolder: _rootURLForManagerWithName(name), andDelegate: delegate)
		
		self._updateUbiquityFolderURL()
		
		NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(_updateUbiquityFolderURL), name:NSUbiquityIdentityDidChangeNotification, object:nil)
	}
	
	public override func startDownloadingItemAtURL(URL: NSURL) throws {
		self._startDownloadingUbiquitousItemAtURL(URL)
		
		try NSFileManager.defaultManager().startDownloadingUbiquitousItemAtURL(URL)
	}
	
}
