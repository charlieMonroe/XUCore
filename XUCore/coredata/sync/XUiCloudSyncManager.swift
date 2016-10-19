//
//  XUiCloudSyncManager.swift
//  XUCore
//
//  Created by Charlie Monroe on 6/3/16.
//  Copyright © 2016 Charlie Monroe Software. All rights reserved.
//

import Foundation

private var _cachedUbiquityURL: URL?
private var _cachedUbiquityToken: (NSObjectProtocol & NSCopying & NSCoding)?

private func _rootURLForManager(named name: String) -> URL? {
	let token = FileManager.default.ubiquityIdentityToken
	if let cachedToken = _cachedUbiquityToken, cachedToken.isEqual(token) {
		return _cachedUbiquityURL
	}
	
	_cachedUbiquityToken = token
	
	guard let ubiquityURL = FileManager.default.url(forUbiquityContainerIdentifier: nil) else {
		_cachedUbiquityURL = nil
		return nil
	}
	
	_cachedUbiquityURL = ubiquityURL
	return ubiquityURL.appendingPathComponent(name)
}

/// Manager for syncing via iCloud.
public final class XUiCloudSyncManager: XUApplicationSyncManager {
	
	
	fileprivate var _rootURL: URL? {
		return _rootURLForManager(named: self.name)
	}
	
	fileprivate func _startDownloadingUbiquitousItem(at URL: URL) {
		if URL.isDirectory {
			let contents = FileManager.default.contentsOfDirectory(at: URL)
			for fileURL in contents {
				self._startDownloadingUbiquitousItem(at: fileURL)
			}
		} else {
			_ = try? FileManager.default.startDownloadingUbiquitousItem(at: URL)
		}
	}
	
	@objc fileprivate func _updateUbiquityFolderURL() {
		if let ubiquityFolderURL = _rootURLForManager(named: self.name) {
			self.syncRootFolderURL = ubiquityFolderURL
			self._startDownloadingUbiquitousItem(at: ubiquityFolderURL)
		}
	}
	
	public init(name: String, andDelegate delegate: XUApplicationSyncManagerDelegate) {
		/// The first time the iCloud gets set up
		
		super.init(name: name, rootFolder: _rootURLForManager(named: name), andDelegate: delegate)
		
		self._updateUbiquityFolderURL()
		
		NotificationCenter.default.addObserver(self, selector: #selector(_updateUbiquityFolderURL), name: .NSUbiquityIdentityDidChange, object: nil)
	}
	
	public override func startDownloading(itemAt url: URL) throws {
		self._startDownloadingUbiquitousItem(at: url)
		
		try FileManager.default.startDownloadingUbiquitousItem(at: url)
	}
	
}
