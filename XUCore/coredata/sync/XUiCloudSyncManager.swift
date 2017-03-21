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
	
	_cachedUbiquityURL = ubiquityURL.appendingPathComponent(name)
	return _cachedUbiquityURL
}

/// Manager for syncing via iCloud.
public final class XUiCloudSyncManager: XUApplicationSyncManager {
	
	
	private var _rootURL: URL? {
		return _rootURLForManager(named: self.name)
	}
	
	private func _startDownloadingUbiquitousItem(at url: URL) {
		if url.isDirectory {
			let contents = FileManager.default.contentsOfDirectory(at: url)
			for fileURL in contents {
				self._startDownloadingUbiquitousItem(at: fileURL)
			}
		} else {
			_ = try? FileManager.default.startDownloadingUbiquitousItem(at: url)
		}
	}
	
	@objc private func _updateUbiquityFolderURL() {
		if let ubiquityFolderURL = self._rootURL {
			XULog("Updating sync root folder to \(ubiquityFolderURL)")
			self.syncRootFolderURL = ubiquityFolderURL
			self._startDownloadingUbiquitousItem(at: ubiquityFolderURL)
		}
	}
	
	public init(name: String, andDelegate delegate: XUApplicationSyncManagerDelegate) {
		/// The first time the iCloud gets set up
		super.init(name: name, rootFolder: _rootURLForManager(named: name), andDelegate: delegate)
		
		XULog("Initialized iCloud sync manager \(self) with name \(name) rooted in \(self.syncRootFolderURL.descriptionWithDefaultValue()).")
		
		self._updateUbiquityFolderURL()
		
		NotificationCenter.default.addObserver(self, selector: #selector(_updateUbiquityFolderURL), name: .NSUbiquityIdentityDidChange, object: nil)
	}
	
	public override func startDownloading(itemAt url: URL) throws {
		self._startDownloadingUbiquitousItem(at: url)
		
		try FileManager.default.startDownloadingUbiquitousItem(at: url)
	}
	
}
