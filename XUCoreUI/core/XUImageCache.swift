//
//  XUImageCache.swift
//  XUCore
//
//  Created by Charlie Monroe on 1/27/21.
//  Copyright © 2021 Charlie Monroe Software. All rights reserved.
//

import Foundation
import XUCore

#if os(iOS)
	import UIKit
#else
	import AppKit

	private extension NSImage {
		
		func pngData() -> Data? {
			return self.pngRepresentation
		}
		
		func resized(to dimension: CGSize) -> NSImage {
			return self.imageWithSingleImageRepresentation(ofSize: dimension) ?? self
		}
		
	}

#endif


protocol ImageCacheIdentifier {
	var cacheIdentifier: String { get }
}

extension ImageCacheIdentifier {
	
	func url(for cache: XUImageCache, size: CGSize?) -> URL {
		let identifier = self.cacheIdentifier
		let imageName: String
		
		if let size = size {
			imageName = "\(identifier)-\(Int(size.width))x\(Int(size.height)).png"
		} else {
			imageName = "\(identifier)-original.png"
		}
		
		return cache.cacheBaseURL.appendingPathComponents(String([identifier.first!]), imageName)
	}
	
}


/// An image cache that loads images and stores them on the persistent storage.
public final class XUImageCache {
		
	/// An in-memory cache entry.
	private struct CacheEntry {
		let image: XUImage
		var lastAccess: TimeInterval = Date.timeIntervalSinceReferenceDate
	}
	
	/// Handler structure gathering the handler owner and the actual handler.
	struct Handler {
		let owner: AnyObject
		let handler: (XUImage?) -> Void
	}
	
	
	/// A simple load structure meant as a token for cancelling the load.
	public struct URLLoadIdentifier: Hashable, ImageCacheIdentifier {
		
		let url: URL
		
		/// Identifier used withing the cache.
		var cacheIdentifier: String {
			return self.url.absoluteString.utf8Data.sha256Digest.hexEncodedString
		}
		
	}
	
	struct AdHocIdentifier: ImageCacheIdentifier {
		
		let identifier: String
		
		var cacheIdentifier: String {
			return self.identifier.utf8Data.sha256Digest.hexEncodedString
		}
		
	}
	
	
	
	
	/// Set of tasks that we are loading.
	@AssertingSetter.MainThread
	private var _loads: [URLLoadIdentifier : (task: URLSessionDataTask, handlers: [Handler])]
	
	
	/// In-memory cache. It is automatically maintained and cleaned.
	@AssertingSetter.MainThread
	private var _memoryCache: [URL : CacheEntry] = [:]
	
	/// Memory pressure source for observing memory pressure.
	private let _memoryPressureSource: DispatchSourceMemoryPressure = DispatchSource.makeMemoryPressureSource(eventMask: [.warning, .critical], queue: .main)
	
	/// Session.
	private let _session: URLSession = URLSession(configuration: .default)
	
	
	/// Base URL - this is the directory where we store all of the content. The
	/// content is further divided based on the leading character of the name
	/// (case insensitive).
	let cacheBaseURL: URL
	
	/// Sizes under which the image is cached. We cache it multiple times at various
	/// resolutions for ideal performance. By default, this is empty and the original
	/// image is cached.
	///
	/// The size does take into account screen scale, so in case the screen is @2x,
	/// the cache uses double the size.
	///
	/// The image is downsized to fit the dimensions proportionally, so the returned
	/// image may be larger.
	let cacheSizes: [CGSize]
	
	/// Name of the cache.
	let name: String

	
	
	private func _cacheImage(_ image: XUImage, for load: ImageCacheIdentifier) {
		if self.cacheSizes.isEmpty {
			self._writeImage(image, url: load.url(for: self, size: nil))
			return
		}
		
		
		let scale: CGFloat
		#if os(iOS)
			scale = UIScreen.main.scale
		#else
			scale = 1.0
		#endif
		
		for size in self.cacheSizes {
			let dimension = size * scale
			let resizedImage = image.resized(to: dimension)
			self._writeImage(resizedImage, url: load.url(for: self, size: size))
		}
	}
	
	/// Cleans an in-memory cache by discarding oldest entries.
	private func _cleanInMemoryCache() {
		while _memoryCache.count > 100 {
			guard let oldest = _memoryCache.findMin({ $0.1.lastAccess }) else {
				break // We're empty?
			}
			
			_memoryCache[oldest.key] = nil
		}
	}
	
	/// Purgeable.
	@objc private func _clearInMemoryCache() {
		_memoryCache = [:]
	}
	
	private func _writeImage(_ image: XUImage, url: URL) {
		guard let pngData = image.pngData() else {
			XULog("Could not create PNG data from \(image)")
			return
		}
		
		let cacheURL = url
		FileManager.default.createDirectory(at: cacheURL.deletingLastPathComponent())
		
		do {
			try pngData.write(to: cacheURL)
			
			DispatchQueue.main.async {
				self._memoryCache[cacheURL] = CacheEntry(image: image)
				self._cleanInMemoryCache()
			}
		} catch {
			XULog("Could not write PNG data to \(cacheURL) due to error: \(error)")
		}
	}
	
	private func _completeLoad(for load: URLLoadIdentifier, data: Data?, error: Error?) {
		if let error = error, error._code == URLError.cancelled.rawValue {
			// This got cancelled, is handled in the cancel method.
			return
		}
		
		let loadDetails = _loads[load]
		
		let image: XUImage?
		if let data = data {
			image = XUImage(data: data)
			if let image = image {
				self._cacheImage(image, for: load)
			} else {
				XULog("Failed to parse image from data: \(data.count) bytes")
			}
		} else {
			XULog("Could not load image at \(load.url) due to error: \(error.descriptionWithDefaultValue())")
			image = nil
		}
		
		if loadDetails == nil {
			return // It was cancelled after the data was already loaded.
		}
		
		DispatchQueue.main.async {
			self._loads[load] = nil
		
			loadDetails?.handlers.forEach({ $0.handler(image) })
		}
	}
	
	/// Reads an image from a file. Will return true in case we are attempting
	/// a local read, return false if there isn't a cached file.
	@discardableResult
	private func _readImage(at fileURL: URL, completionHandler: @escaping (XUImage?) -> Void) -> Bool {
		if let image = _memoryCache[fileURL]?.image {
			completionHandler(image)
			_memoryCache[fileURL]!.lastAccess = Date.timeIntervalSinceReferenceDate
			return true
		}
		
		if
			(try? fileURL.checkResourceIsReachable()) == true
		{
			DispatchQueue.global().async {
				let data = try? Data(contentsOf: fileURL)
				let image = data.flatMap(XUImage.init(data:))
				DispatchQueue.main.async {
					if let image = image {
						self._memoryCache[fileURL] = CacheEntry(image: image)
						self._cleanInMemoryCache()
					}
					completionHandler(image)
				}
			}
			return true
		}
		
		return false
	}
	
	/// Caches an image with an identifier.
	public func cacheImage(_ image: XUImage, for identifier: String) {
		XUAssertMainThread()
		
		DispatchQueue.global().async {
			self._cacheImage(image, for: AdHocIdentifier(identifier: identifier))
		}
	}
	
	/// Returns a cached image for a certain resolution (if available). If the resolution
	/// is not in self.cacheSizes, a closest one is returned. If not sizes are defined,
	/// the argument is ignored and the original is returned.
	///
	/// If sizes are defined and resolution is nil, the largest one is used.
	public func loadCachedImage(for identifier: String, resolution: CGSize? = nil, completionHandler: @escaping (XUImage?) -> Void) {
		XUAssertMainThread()
		
		guard let size = resolution else {
			let fileURL = AdHocIdentifier(identifier: identifier).url(for: self, size: self.cacheSizes.sorted(using: \.width).last)
			if !self._readImage(at: fileURL, completionHandler: completionHandler) {
				completionHandler(nil)
			}
			return
		}
		
		var targetDimension = CGSize.zero
		for cacheDimension in self.cacheSizes.sorted(using: \.width) {
			targetDimension = cacheDimension
			if size.width < targetDimension.width {
				break
			}
		}
		
		let fileURL = AdHocIdentifier(identifier: identifier).url(for: self, size: targetDimension)
		if !self._readImage(at: fileURL, completionHandler: completionHandler) {
			completionHandler(nil)
		}
	}
	
	/// Cancels the load of the URL, just for that handler owner. If there are other
	/// handlers waiting for the load, they are not cancelled. The handleOwner
	/// still receives the handler call with nil.
	///
	/// This should be called on main thread.
	public func cancelLoad(for load: URLLoadIdentifier, handlerOwner: AnyObject) {
		XUAssertMainThread()
		
		if let loadDetails = _loads[load] {
			if loadDetails.handlers.count == 1 {
				// There's just one handler, cancel the whole load.
				_loads[load] = nil
				
				loadDetails.task.cancel()
				
				loadDetails.handlers.forEach({ $0.handler(nil) })
			} else if let index = loadDetails.handlers.firstIndex(where: { $0.owner === handlerOwner }) {
				let handler = loadDetails.handlers[index]
				_loads[load]!.handlers.remove(at: index)
				
				handler.handler(nil)
			}
		}
	}
	
	/// Loads an image for URL. If the URL is in the cache, the completionHandler
	/// gets immediately invoked. If this is not the case, the image gets loaded
	/// from the Internet.
	///
	/// If there already is a request for this resource, the hanlder only gets queued.
	///
	/// Pass `handlerOwner` which is then used for cancellation of the load. In case
	/// there are multiple handlers waiting for the same image, we don't want to
	/// remove all of the handlers during the cancel.
	public func loadImage(for url: URL, size: CGSize, completionHandler: @escaping (XUImage?) -> Void, handlerOwner: AnyObject) -> URLLoadIdentifier? {
		XUAssertMainThread()
		
		var targetDimension = CGSize.zero
		for cacheDimension in self.cacheSizes.sorted(using: \.width) {
			targetDimension = cacheDimension
			if size.width < targetDimension.width {
				break
			}
		}
		
		let load = URLLoadIdentifier(url: url)
		let fileURL = load.url(for: self, size: targetDimension == .zero ? nil : targetDimension)
		
		if self._readImage(at: fileURL, completionHandler: completionHandler) {
			return nil
		}
		
		if _loads[load] != nil {
			_loads[load]!.handlers.append(Handler(owner: handlerOwner, handler: completionHandler))
		} else {
			let task = _session.dataTask(with: url) { (data, _, error) in
				self._completeLoad(for: load, data: data, error: error)
			}
			
			_loads[load] = (task, [Handler(owner: handlerOwner, handler: completionHandler)])
			task.resume()
		}
		
		return load
	}
	
	
	public init(name: String, sizes: [CGSize] = []) {
		self.cacheSizes = sizes
		self.name = name
		
		var cacheBaseURL = FileManager.Directories.applicationSupportDirectory
		cacheBaseURL.appendPathComponent(XUAppSetup.applicationIdentifier)
		cacheBaseURL.appendPathComponent(name)
		
		FileManager.default.createDirectory(at: cacheBaseURL)
		
		do {
			// We need to exclude the cache from backups - Apple would otherwise
			// reject the app.
			var values = URLResourceValues()
			values.isExcludedFromBackup = true
			
			try cacheBaseURL.setResourceValues(values)
		} catch {
			XULog("Failed to exclude \(cacheBaseURL) from backups due to \(error)")
		}
		
		self.cacheBaseURL = cacheBaseURL
		self._loads = [:]
		
		DispatchQueue.main.async {
			self._memoryPressureSource.setEventHandler { [weak self] in
				self?._cleanInMemoryCache()
			}
			self._memoryPressureSource.resume()
		}
	}
	
}
