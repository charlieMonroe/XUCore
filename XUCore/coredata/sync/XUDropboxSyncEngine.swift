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
/// locally. This allows us to use the NSFileManager-based sync.
public class XUDropboxSyncManager: XUApplicationSyncManager {
	
	private var _failedFileUploads: [NSURL] {
		didSet {
			self._save()
		}
	}
	
	private var _modificationDates: [String : NSDate] {
		didSet {
			self._save()
		}
	}
	private let _setupURL: NSURL

	private var _syncCounter: Int = 0 {
		didSet {
			if _syncCounter == 0 {
				self._synchronizationDidEnd()
			}
		}
	}
	
	private let _rootFolder: NSURL
	private var _syncTimer: NSTimer?
	
	let client: DropboxClient
	
	private func _createFolderAtURL(folderURL: NSURL) {
		let path = self._relativePathToURL(folderURL)
		self.client.files.createFolder(path: path).response({ _, error in
			// Ignore. This is likely just the folder already existing.
		})
	}
	
	private func _downloadFileAtPath(filePath: String) {
		_syncCounter += 1
		
		let targetURL = self._rootFolder.URLByAppendingPathComponent(filePath)
		self.client.files.download(path: filePath, destination: { _ -> NSURL in
			_ = try? NSFileManager.defaultManager().removeItemAtURL(targetURL)
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
	
	private func _handleListingResultAtPath<T>(path: String, result: Files.ListFolderResult?, error: CallError<T>?) {
		defer {
			_syncCounter -= 1
		}
		
		guard let result = result else {
			XULog("Failed to list folder at path \(path) due to error \(error.descriptionWithDefaultValue())")
			return
		}
		
		NSFileManager.defaultManager().createDirectoryAtURL(_rootFolder.URLByAppendingPathComponent(path))
		
		if result.hasMore {
			_syncCounter += 1
			self.client.files.listFolderContinue(cursor: result.cursor).response({ self._handleListingResultAtPath(path, result: $0, error: $1) })
		}
		
		for fileEntry in result.entries {
			if let folder = fileEntry as? Files.FolderMetadata {
				self._syncFilesAtPath(path + "/" + folder.name)
				continue
			}
			
			guard let file = fileEntry as? Files.FileMetadata else {
				XULog("Unknown metadata type \(fileEntry.dynamicType): \(fileEntry)")
				continue
			}
			
			let filePath = path + "/" + file.name
			if let date = _modificationDates[filePath] where file.serverModified.isBeforeDate(date) {
				/// The dates match
				continue
			}
			
			/// We need to download the file.
			self._downloadFileAtPath(filePath)
		}
	}
	
	private func _relativePathToURL(fileURL: NSURL) -> String {
		let path = fileURL.path!
		let rootPath = _rootFolder.path!
		assert(path.hasPrefix(rootPath), "Trying to upload a file that is out of the Dropbox sync sandbox.")
		
		return path.stringByDeletingPrefix(rootPath)
	}
	
	private func _save() {
		let dict = [
			XUDropboxSetupFailedUploadsKey: self._failedFileUploads.map({ $0.path! }),
			XUDropboxSetupModificationDatesKey: self._modificationDates
		]
		dict.writeToURL(self._setupURL, atomically: true)
	}
	
	@objc private func _syncFiles() {
		if self.isDownloadingData {
			return // Already syncing.
		}
		
		self._syncFilesAtPath("")
		
		/// Try to re-upload failed file uploads
		for fileURL in _failedFileUploads {
			self._uploadFileAtURL(fileURL)
		}
	}
	
	private func _syncFilesAtPath(path: String) {
		_syncCounter += 1
		self.client.files.listFolder(path: path).response { (result, error) in
			self._handleListingResultAtPath(path, result: result, error: error)
		}
	}
	
	private func _synchronizationDidEnd() {
		self.scanForNewDocuments()
	}
	
	private func _uploadFileAtURL(fileURL: NSURL) {
		let path = self._relativePathToURL(fileURL)
		self.client.files.upload(path: path, mode: .Overwrite, body: fileURL).response { (result, error) in
			if error != nil {
				XULog("Failed to upload file at path \(path) - queued reupload.")
				
				if self._failedFileUploads.indexOf(fileURL) == nil {
					self._failedFileUploads.append(fileURL)
				}
				return
			}
			
			self._modificationDates[path] = result!.serverModified
			
			if let index = self._failedFileUploads.indexOf(fileURL) {
				self._failedFileUploads.removeAtIndex(index)
			}
		}
	}
	
	public override func createDirectoryAtURL(URL: NSURL) throws {
		try super.createDirectoryAtURL(URL)
		
		self._createFolderAtURL(URL)
	}
	
	deinit {
		_syncTimer?.invalidate()
	}
	
	public override func didUpdateFileAtURL(fileURL: NSURL) {
		if fileURL.isDirectory {
			self._createFolderAtURL(fileURL)
			
			for file in NSFileManager.defaultManager().contentsOfDirectoryAtURL(fileURL) {
				self.didUpdateFileAtURL(file)
			}
		} else {
			self._uploadFileAtURL(fileURL)
		}
	}
	
	public init(name: String, client: DropboxClient, andDelegate delegate: XUApplicationSyncManagerDelegate) {
		self.client = client
		
		guard var rootURL = try? NSFileManager.defaultManager().URLForDirectory(.ApplicationSupportDirectory, inDomain: .UserDomainMask, appropriateForURL: nil, create: true) else {
			fatalError("Can't create Application Support directory!")
		}
		
		rootURL = rootURL.URLByAppendingPathComponent("DropBox.sync")
		NSFileManager.defaultManager().createDirectoryAtURL(rootURL)
		
		_setupURL = rootURL.URLByAppendingPathComponent("Setup.plist")
		if let dict = NSDictionary(contentsOfURL: _setupURL) as? XUJSONDictionary {
			_modificationDates = (dict[XUDropboxSetupModificationDatesKey] as? [String : NSDate]) ?? [:]
			if let failedUploadPaths = dict[XUDropboxSetupFailedUploadsKey] as? [String] {
				_failedFileUploads = failedUploadPaths.map({ NSURL(fileURLWithPath: $0) })
			} else {
				_failedFileUploads = []
			}
		} else {
			_failedFileUploads = []
			_modificationDates = [ : ]
		}
		
		rootURL = rootURL.URLByAppendingPathComponent("Contents")
		NSFileManager.defaultManager().createDirectoryAtURL(rootURL)
		
		_rootFolder = rootURL
		
		super.init(name: name, rootFolder: rootURL, andDelegate: delegate)
		
		self._syncFiles()
		_syncTimer = NSTimer.scheduledTimerWithTimeInterval(90.0, target: self, selector: #selector(_syncFiles), userInfo: nil, repeats: true)
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
	
	public override func startDownloadingItemAtURL(URL: NSURL) throws {
		// No-op, since it's already downloaded.
	}
	
}
