//
//  XUApplicationSyncManager.swift
//  XUCore
//
//  Created by Charlie Monroe on 5/23/16.
//  Copyright © 2016 Charlie Monroe Software. All rights reserved.
//

import Foundation

public protocol XUApplicationSyncManagerDelegate: AnyObject {
	
	/// Called when the manager found a new document. It might not be downloaded yet.
	func applicationSyncManager(manager: XUApplicationSyncManager, didFindNewDocumentWithID documentID: String)
	
}

private func _XULogFileAtURL(rootURL: NSURL, fileURL: NSURL, level: Int) {
	for _ in 0 ..< level {
		print("|\t", terminator: "")
	}
	
	// Just print relative path
	let path = fileURL.lastPathComponent ?? "<<no lastPathComponent>>"
	print("- \(path)");
	
	// Don't care if the URL isn't a folder - file mananger will simple return
	// nothing
	for aURL in NSFileManager.defaultManager().contentsOfDirectoryAtURL(fileURL) {
		_XULogFileAtURL(rootURL, fileURL: aURL, level: level + 1)
	}
}

private func _XULogFolderContentsStartingAtURL(rootURL: NSURL?, manager: XUApplicationSyncManager) {
	if rootURL == nil {
		print("====================================================")
		print("| \(manager).rootURL == nil -> not enabled. |")
		print("====================================================")
		return
	}
	
	print("====== Printing \(manager).rootURL Contents [\(XU_SYNC_DEVICE_ID())] ======")
	_XULogFileAtURL(rootURL!, fileURL: rootURL!, level: 0);
}


private let XUApplicationSyncManagerDownloadedDocumentIDsDefaultsKey = "XUApplicationSyncManagerDownloadedDocumentIDs"

private let XUApplicationSyncManagerErrorDomain = "XUApplicationSyncManagerErrorDomain"

/// This is an abstract class that represents a sync manager. You should only
/// create one instance per subclass within the app.
public class XUApplicationSyncManager {
	
	/// Timer that checks for new documents every 30 seconds.
	private var _documentCheckerTimer: NSTimer!
	
	/// UUIDs of documents that have been downloaded.
	private var _downloadedDocumentUUIDs: [String] = []
	
	/// Use query to detect new files on iCloud and download them.
	private let _metadataQuery: NSMetadataQuery = NSMetadataQuery()

	/// UUIDs of documents that have been downloaded or up for download.
	public private(set) var availableDocumentUUIDs: [String] = []
	
	/// Delegate of the app sync manager.
	public weak var delegate: XUApplicationSyncManagerDelegate?
	
	/// Name of the app, usually. Whatever passed in -initWithName:.
	public let name: String
	
	/// URL of the folder that's designated for sync data for this manager.
	///
	/// URL of the folder that contains the documents for this sync manager.
	/// The folder mustn't be created until whole store upload in order to eliminate
	/// any potential duplicates.
	///
	/// Changes to this var should only be done by subclasses.
	public var syncRootFolderURL: NSURL?

	
	
	private func _checkForNewDocuments() {
		if self.syncRootFolderURL == nil {
			return
		}
	
		let contents = NSFileManager.defaultManager().contentsOfDirectoryAtURL(self.syncRootFolderURL!)
		for fileURL in contents {
			guard let documentUUID = fileURL.lastPathComponent else {
				continue
			}
			
			if documentUUID == ".DS_Store" {
				continue // Just a precaution
			}
	
			// If the _availableDocumentUUIDs contains documentUUID, the document
			// either has been already downloaded, or it has already been announced
			// to the delegate.
			if self.availableDocumentUUIDs.contains(documentUUID) {
				continue
			}
	
			self.availableDocumentUUIDs.append(documentUUID)
			self.delegate?.applicationSyncManager(self, didFindNewDocumentWithID: documentUUID)
		}
	}
	
	@objc private func _metadataQueryGotUpdated(aNotif: NSNotification) {
		for obj in _metadataQuery.results {
			guard let item = obj as? NSMetadataItem else {
				continue
			}
	
			guard let URL = item.valueForAttribute(NSMetadataItemURLKey) as? NSURL else {
				continue
			}
	
			do {
				try self.startDownloadingItemAtURL(URL)
			} catch let error as NSError {
				XULog("Failed to start downloading item at URL \(URL) because \(error)")
			}
		}
	}

	/// Should create a folder at URL. By default, this only invokes NSFileManager,
	/// but subclasses may do additional work, such as contacting the server.
	public func createDirectoryAtURL(URL: NSURL) throws {
		try NSFileManager.defaultManager().createDirectoryAtURL(URL, withIntermediateDirectories: true, attributes: nil)
	}
	
	/// The document manager will notify the app sync manager that it has written
	/// into (or created) a file at fileURL. Note that the fileURL may lead to a
	/// folder. Use this on subclasses to upload the file. Note that if the upload
	/// fails, the subclass is responsible for deferring the upload.
	public func didUpdateFileAtURL(fileURL: NSURL) {
		/// No-op.
	}
	
	/// Downloads or copies document with ID to URL and calls completion handler
	/// upon completion. The handler is always called on the main thread.
	///
	/// The documentURL within the response is nonnull upon success and contains 
	/// a URL to the document file.
	public func downloadDocumentWithID(documentID: String, toURL fileURL: NSURL, withCompletionHandler completionHandler: (success: Bool, documentURL: NSURL?, error: NSError?) -> Void) {
		XU_PERFORM_BLOCK_ASYNC { 
			var err: NSError?
			var documentURL: NSURL?
			do {
				documentURL = try XUDocumentSyncManager.downloadDocumentWithID(documentID, forApplicationSyncManager: self, toURL: fileURL)
			} catch let error as NSError {
				err = error
			}
			
			XU_PERFORM_BLOCK_ON_MAIN_THREAD {
				// Remove document ID from available, since the download failed
				if documentURL == nil {
					if let index = self.availableDocumentUUIDs.indexOf(documentID) {
						self.availableDocumentUUIDs.removeAtIndex(index)
					}
				}
				
				completionHandler(success: documentURL != nil, documentURL: documentURL, error: err);
			}
		}
	}
	
	/// Designated initialized. Name should be e.g. name of the app.
	public init(name: String, rootFolder: NSURL?, andDelegate delegate: XUApplicationSyncManagerDelegate) {
		self.name = name
		self.delegate = delegate
		self.syncRootFolderURL = rootFolder
		
		if let downloadedDocumentUUIDs = NSUserDefaults.standardUserDefaults().arrayForKey(XUApplicationSyncManagerDownloadedDocumentIDsDefaultsKey) as? [String] {
			_downloadedDocumentUUIDs += downloadedDocumentUUIDs
			self.availableDocumentUUIDs += downloadedDocumentUUIDs
		}
		
		_documentCheckerTimer = NSTimer.scheduledTimerWithTimeInterval(30.0, target: self, selector: #selector(scanForNewDocuments), userInfo: nil, repeats: true)
		
		self._checkForNewDocuments()
		
		self.logRootSyncFolderContents()
		
		NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(_metadataQueryGotUpdated(_:)), name:NSMetadataQueryDidUpdateNotification, object: _metadataQuery)
		NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(_metadataQueryGotUpdated(_:)), name:NSMetadataQueryDidFinishGatheringNotification, object: _metadataQuery)
		
		_metadataQuery.startQuery()
	}
	
	/// Debugging method that logs all contents on the folder at syncRootFolderURL.
	public func logRootSyncFolderContents() {
		_XULogFolderContentsStartingAtURL(self.syncRootFolderURL?.URLByDeletingLastPathComponent, manager: self)
	}
	
	/// Starts scanning for new documents.
	@objc public func scanForNewDocuments() {
		self._checkForNewDocuments()
	}
	
	/// Start downloading item at URL. The metadata query should automatically 
	/// notice when the download is done. You can call scanForNewDocuments()
	/// to make sure, though.
	public func startDownloadingItemAtURL(URL: NSURL) throws {
		XUThrowAbstractException("\(self)")
	}
	
	
	
	
}
