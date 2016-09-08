//
//  XUiCloudSyncManager.swift
//  XUCore
//
//  Created by Charlie Monroe on 6/3/16.
//  Copyright © 2016 Charlie Monroe Software. All rights reserved.
//

import Foundation

private func _rootURLForManagerWithName(_ name: String) -> URL? {
	return FileManager.default.url(forUbiquityContainerIdentifier: nil)?.appendingPathComponent(name)
}

/// Manager for syncing via iCloud.
open class XUiCloudSyncManager: XUApplicationSyncManager {
	
	
	fileprivate var _rootURL: URL? {
		return _rootURLForManagerWithName(self.name)
	}
	
	fileprivate func _startDownloadingUbiquitousItemAtURL(_ URL: Foundation.URL) {
		if URL.isDirectory {
			let contents = FileManager.default.contentsOfDirectoryAtURL(URL)
			for fileURL in contents {
				self._startDownloadingUbiquitousItemAtURL(fileURL)
			}
		} else {
			_ = try? FileManager.default.startDownloadingUbiquitousItem(at: URL)
		}
	}
	
	@objc fileprivate func _updateUbiquityFolderURL() {
		if let ubiquityFolderURL = FileManager.default.url(forUbiquityContainerIdentifier: nil)?.appendingPathComponent(self.name) {
			self.syncRootFolderURL = ubiquityFolderURL
			self._startDownloadingUbiquitousItemAtURL(ubiquityFolderURL)
		}
	}
	
	public init(name: String, andDelegate delegate: XUApplicationSyncManagerDelegate) {
		super.init(name: name, rootFolder: _rootURLForManagerWithName(name), andDelegate: delegate)
		
		self._updateUbiquityFolderURL()
		
		NotificationCenter.default.addObserver(self, selector: #selector(_updateUbiquityFolderURL), name:NSNotification.Name.NSUbiquityIdentityDidChange, object:nil)
	}
	
	open override func startDownloadingItemAtURL(_ URL: Foundation.URL) throws {
		self._startDownloadingUbiquitousItemAtURL(URL)
		
		try FileManager.default.startDownloadingUbiquitousItem(at: URL)
	}
	
}
