//
//  XUApplicationSyncManager.swift
//  XUCore
//
//  Created by Charlie Monroe on 5/23/16.
//  Copyright © 2016 Charlie Monroe Software. All rights reserved.
//

import Foundation

@available(iOSApplicationExtension, unavailable)
public protocol XUApplicationSyncManagerDelegate: AnyObject {
	
	/// Called when the manager found a new document. It might not be downloaded yet.
	func applicationSyncManager(_ manager: XUApplicationSyncManager, didFindNewDocumentWithID documentID: String)
	
}

private func _XULogFileAtURL(_ rootURL: URL, fileURL: URL, level: Int) {
	for _ in 0 ..< level {
		print("|\t", terminator: "")
	}
	
	// Just print relative path
	let path = fileURL.lastPathComponent 
	print("- \(path)");
	
	// Don't care if the URL isn't a folder - file mananger will simple return
	// nothing
	for aURL in FileManager.default.contentsOfDirectory(at: fileURL) {
		_XULogFileAtURL(rootURL, fileURL: aURL, level: level + 1)
	}
}

@available(iOSApplicationExtension, unavailable)
private func _XULogFolderContentsStartingAtURL(_ rootURL: URL?, manager: XUApplicationSyncManager) {
	guard XUDebugLog.isLoggingEnabled else {
		return
	}
	
	if rootURL == nil {
		print("====================================================")
		print("| \(manager).rootURL == nil -> not enabled. |")
		print("====================================================")
		return
	}
	
	print("====== Printing \(manager).rootURL Contents [\(XUSyncManagerPathUtilities.currentDeviceIdentifier)] ======")
	_XULogFileAtURL(rootURL!, fileURL: rootURL!, level: 0);
}

private extension XUPreferences.Key {
	static let ApplicationSyncManagerDownloadedDocumentIDs = XUPreferences.Key(rawValue: "XUApplicationSyncManagerDownloadedDocumentIDs")
}

private extension XUPreferences {
	
	var downloadedDocumentIDs: [String]? {
		get {
			return self.value(for: .ApplicationSyncManagerDownloadedDocumentIDs)
		}
		set {
			self.set(value: newValue, forKey: .ApplicationSyncManagerDownloadedDocumentIDs)
		}
	}
	
}

private let XUApplicationSyncManagerErrorDomain = "XUApplicationSyncManagerErrorDomain"

/// This is an abstract class that represents a sync manager. You should only
/// create one instance per subclass within the app.
@available(iOSApplicationExtension, unavailable)
open class XUApplicationSyncManager {
	
	/// Timer that checks for new documents every 30 seconds.
	private var _documentCheckerTimer: Timer!
	
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
	public var syncRootFolderURL: URL?

	
	
	private func _checkForNewDocuments() {
		if self.syncRootFolderURL == nil {
			return
		}
	
		let contents = FileManager.default.contentsOfDirectory(at: self.syncRootFolderURL!)
		for fileURL in contents {
			let documentUUID = fileURL.lastPathComponent
			if documentUUID == ".DS_Store" || documentUUID.isEmpty {
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
	
	@objc private func _metadataQueryGotUpdated(_ aNotif: Notification) {
		for obj in _metadataQuery.results {
			guard let item = obj as? NSMetadataItem else {
				continue
			}
	
			guard let url = item.value(forAttribute: NSMetadataItemURLKey) as? URL else {
				continue
			}
	
			do {
				try self.startDownloading(itemAt: url)
			} catch let error as NSError {
				XULog("Failed to start downloading item at URL \(url) because \(error)")
			}
		}
	}
	
	/// Should create a folder at URL. By default, this only invokes NSFileManager,
	/// but subclasses may do additional work, such as contacting the server.
	open func createDirectory(at url: URL) throws {
		try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
	}
	
	/// The document manager will notify the app sync manager that it has written
	/// into (or created) a file at fileURL. Note that the fileURL may lead to a
	/// folder. Use this on subclasses to upload the file. Note that if the upload
	/// fails, the subclass is responsible for deferring the upload.
	open func didUpdateFile(at fileURL: URL) {
		/// No-op.
	}
	
	/// Downloads or copies document with ID to URL and calls completion handler
	/// upon completion. The handler is always called on the main thread.
	///
	/// The documentURL within the response is nonnull upon success and contains 
	/// a URL to the document file.
	open func downloadDocument(withID documentID: String, toURL fileURL: URL, withCompletionHandler completionHandler: @escaping (_ success: Bool, _ documentURL: URL?, _ error: NSError?) -> Void) {
		DispatchQueue.global(qos: .default).async { 
			var err: NSError?
			var documentURL: URL?
			do {
				documentURL = try XUDocumentSyncManager.downloadDocument(withID: documentID, forApplicationSyncManager: self, toURL: fileURL)
			} catch let error as NSError {
				err = error
			}
			
			DispatchQueue.main.syncOrNow {
				// Remove document ID from available, since the download failed
				if documentURL == nil {
					if let index = self.availableDocumentUUIDs.index(of: documentID) {
						self.availableDocumentUUIDs.remove(at: index)
					}
				}
				
				completionHandler(documentURL != nil, documentURL, err);
			}
		}
	}
	
	/// Designated initialized. Name should be e.g. name of the app.
	public init(name: String, rootFolder: URL?, andDelegate delegate: XUApplicationSyncManagerDelegate) {
		self.name = name
		self.delegate = delegate
		self.syncRootFolderURL = rootFolder
		
		if let downloadedDocumentUUIDs = XUPreferences.shared.downloadedDocumentIDs {
			_downloadedDocumentUUIDs += downloadedDocumentUUIDs
			self.availableDocumentUUIDs += downloadedDocumentUUIDs
		}
		
		_documentCheckerTimer = Timer.scheduledTimer(timeInterval: 30.0, target: self, selector: #selector(scanForNewDocuments), userInfo: nil, repeats: true)
		
		self._checkForNewDocuments()
		
		self.logRootSyncFolderContents()
		
		NotificationCenter.default.addObserver(self, selector: #selector(_metadataQueryGotUpdated(_:)), name:NSNotification.Name.NSMetadataQueryDidUpdate, object: _metadataQuery)
		NotificationCenter.default.addObserver(self, selector: #selector(_metadataQueryGotUpdated(_:)), name:NSNotification.Name.NSMetadataQueryDidFinishGathering, object: _metadataQuery)
		
		_metadataQuery.start()
	}
	
	/// Return true if the manager is currently downloading data. If yes, the 
	/// document manager will postpone the sync.
	open var isDownloadingData: Bool {
		return false
	}
	
	/// Debugging method that logs all contents on the folder at syncRootFolderURL.
	open func logRootSyncFolderContents() {
		_XULogFolderContentsStartingAtURL(self.syncRootFolderURL?.deletingLastPathComponent(), manager: self)
	}
	
	/// Starts scanning for new documents.
	@objc open func scanForNewDocuments() {
		self._checkForNewDocuments()
	}
	
	/// Start downloading item at URL. The metadata query should automatically 
	/// notice when the download is done. You can call scanForNewDocuments()
	/// to make sure, though.
	open func startDownloading(itemAt url: URL) throws {
		XUFatalError("\(self)")
	}
	
	
	
	
}
