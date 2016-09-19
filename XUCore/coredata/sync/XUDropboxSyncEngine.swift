//
//  XUDropboxSyncEngine.swift
//  UctoX 2 iOS
//
//  Created by Charlie Monroe on 6/7/16.
//  Copyright © 2016 Charlie Monroe Software. All rights reserved.
//

import Foundation
import SwiftyDropbox
import XUCore

/// This is a subclass of XUApplicationSyncManager meant to sync with Dropbox.
/// It is bundled with XUCore for the sake of completeness, but it is not included
/// in the build phase due to its dependency on SwiftyDropbox.
///
/// If you wish to use it, you need to add it to your app directly along with the
/// SwiftyDropbox SDK.


private let XUDropboxSetupModificationDatesKey = "XUDropboxSetupModificationDates"
private let XUDropboxSetupFailedUploadsKey = "XUDropboxSetupFailedUploads"

/// Since it's all asynchronous with dropbox, we solve this by copying everything
/// locally. This allows us to use the FileManager-based sync.
public class XUDropboxSyncManager: XUApplicationSyncManager {
	
	fileprivate var _failedFileUploads: [URL] {
		didSet {
			self._save()
		}
	}
	
	fileprivate var _modificationDates: [String : Date] {
		didSet {
			self._save()
		}
	}
	fileprivate let _setupURL: URL

	fileprivate var _syncCounter: Int = 0 {
		didSet {
			if _syncCounter == 0 {
				self._synchronizationDidEnd()
			}
		}
	}
	
	fileprivate let _rootFolder: URL
	fileprivate var _syncTimer: Timer?
	
	public let client: DropboxClient
	
	fileprivate func _createFolderAtURL(_ folderURL: URL) {
		let path = self._relativePathToURL(folderURL)
		_ = self.client.files.createFolder(path: path).response({ _, error in
			// Ignore. This is likely just the folder already existing.
		})
	}
	
	fileprivate func _downloadFileAtPath(_ filePath: String) {
		_syncCounter += 1
		
		let targetURL = self._rootFolder.appendingPathComponent(filePath)
		_ = self.client.files.download(path: filePath, destination: { _ -> URL in
			_ = try? FileManager.default.removeItem(at: targetURL)
			return targetURL
		}).response({ (response, error) in
			defer {
				self._syncCounter -= 1
			}
			
			if response == nil {
				XULog("Failed to download file at path \(filePath) due to error \(error.descriptionWithDefaultValue())")
				return
			}
			
			let date = response!.0.serverModified
			self._modificationDates[filePath] = date
		})
	}
	
	fileprivate func _handleListingResultAtPath<T>(_ path: String, result: Files.ListFolderResult?, error: CallError<T>?) {
		defer {
			_syncCounter -= 1
		}
		
		guard let result = result else {
			XULog("Failed to list folder at path \(path) due to error \(error.descriptionWithDefaultValue())")
			return
		}
		
		FileManager.default.createDirectory(at: _rootFolder.appendingPathComponent(path))
		
		if result.hasMore {
			_syncCounter += 1
			_ = self.client.files.listFolderContinue(cursor: result.cursor).response({ self._handleListingResultAtPath(path, result: $0, error: $1) })
		}
		
		for fileEntry in result.entries {
			if let folder = fileEntry as? Files.FolderMetadata {
				self._syncFilesAtPath(path + "/" + folder.name)
				continue
			}
			
			guard let file = fileEntry as? Files.FileMetadata else {
				XULog("Unknown metadata type \(type(of: fileEntry)): \(fileEntry)")
				continue
			}
			
			let filePath = path + "/" + file.name
			if let date = _modificationDates[filePath] , file.serverModified.isBefore(date) {
				/// The dates match
				continue
			}
			
			/// We need to download the file.
			self._downloadFileAtPath(filePath)
		}
	}
	
	fileprivate func _relativePathToURL(_ fileURL: URL) -> String {
		let path = fileURL.path
		let rootPath = _rootFolder.path
		assert(path.hasPrefix(rootPath), "Trying to upload a file that is out of the Dropbox sync sandbox.")
		
		return path.deleting(prefix: rootPath)
	}
	
	fileprivate func _save() {
		let dict = [
			XUDropboxSetupFailedUploadsKey: self._failedFileUploads.map({ $0.path }),
			XUDropboxSetupModificationDatesKey: self._modificationDates
		] as [String : Any]
		(dict as NSDictionary).write(to: self._setupURL, atomically: true)
	}
	
	@objc fileprivate func _syncFiles() {
		if self.isDownloadingData {
			return // Already syncing.
		}
		
		self._syncFilesAtPath("")
		
		/// Try to re-upload failed file uploads
		for fileURL in _failedFileUploads {
			self._uploadFileAtURL(fileURL)
		}
	}
	
	fileprivate func _syncFilesAtPath(_ path: String) {
		_syncCounter += 1
		_ = self.client.files.listFolder(path: path).response { (result, error) in
			self._handleListingResultAtPath(path, result: result, error: error)
		}
	}
	
	fileprivate func _synchronizationDidEnd() {
		self.scanForNewDocuments()
	}
	
	fileprivate func _uploadFileAtURL(_ fileURL: URL) {
		let path = self._relativePathToURL(fileURL)
		_ = self.client.files.upload(path: path, mode: Files.WriteMode.overwrite, input: fileURL).response { (result, error) in
			if error != nil {
				XULog("Failed to upload file at path \(path) - queued reupload.")
				
				if self._failedFileUploads.index(of: fileURL) == nil {
					self._failedFileUploads.append(fileURL)
				}
				return
			}
			
			self._modificationDates[path] = result!.serverModified
			
			if let index = self._failedFileUploads.index(of: fileURL) {
				self._failedFileUploads.remove(at: index)
			}
		}
	}
	
	public override func createDirectory(at URL: Foundation.URL) throws {
		try super.createDirectory(at: URL)
		
		self._createFolderAtURL(URL)
	}
	
	deinit {
		_syncTimer?.invalidate()
	}
	
	public override func didUpdateFile(at fileURL: URL) {
		if fileURL.isDirectory {
			self._createFolderAtURL(fileURL)
			
			for file in FileManager.default.contentsOfDirectory(at: fileURL) {
				self.didUpdateFile(at: file)
			}
		} else {
			self._uploadFileAtURL(fileURL)
		}
	}
	
	public init(name: String, client: DropboxClient, andDelegate delegate: XUApplicationSyncManagerDelegate) {
		self.client = client
		
		guard var rootURL = try? FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true) else {
			fatalError("Can't create Application Support directory!")
		}
		
		rootURL = rootURL.appendingPathComponent("DropBox.sync")
		FileManager.default.createDirectory(at: rootURL)
		
		_setupURL = rootURL.appendingPathComponent("Setup.plist")
		if let dict = NSDictionary(contentsOf: _setupURL) as? XUJSONDictionary {
			_modificationDates = (dict[XUDropboxSetupModificationDatesKey] as? [String : Date]) ?? [:]
			if let failedUploadPaths = dict[XUDropboxSetupFailedUploadsKey] as? [String] {
				_failedFileUploads = failedUploadPaths.map({ URL(fileURLWithPath: $0) })
			} else {
				_failedFileUploads = []
			}
		} else {
			_failedFileUploads = []
			_modificationDates = [ : ]
		}
		
		rootURL = rootURL.appendingPathComponent("Contents")
		FileManager.default.createDirectory(at: rootURL)
		
		_rootFolder = rootURL
		
		super.init(name: name, rootFolder: rootURL, andDelegate: delegate)
		
		self._syncFiles()
		_syncTimer = Timer.scheduledTimer(timeInterval: 90.0, target: self, selector: #selector(_syncFiles), userInfo: nil, repeats: true)
	}
	
	/// Returns true if we're downloading data from Dropbox.
	public var isDownloadingData: Bool {
		return _syncCounter != 0
	}
	
	public override func scanForNewDocuments() {
		if self.isDownloadingData {
			return // Wait for the next time
		}
		
		super.scanForNewDocuments()
	}
	
	public override func startDownloading(itemAt URL: Foundation.URL) throws {
		// No-op, since it's already downloaded.
	}
	
}
