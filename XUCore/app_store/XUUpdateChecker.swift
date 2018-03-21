//
//  XUUpdateChecker.swift
//  XUCore
//
//  Created by Charlie Monroe on 3/19/18.
//  Copyright © 2018 Charlie Monroe Software. All rights reserved.
//

import Foundation

#if os(macOS)
	import AppKit
#else
	import UIKit
#endif

/// This class handles checking for updates based on the app's bundle identifier.
/// As this check is done against the AppStore, the app must be distributed via
/// the AppStore.
public final class XUUpdateChecker {
	
	/// Result of the version checking.
	public enum Result {
		
		/// This indicates either no Internet connection or that the app is not
		/// on the AppStore yet, or some other issue occurred.
		case failure
		
		/// We are running the latest version.
		case noUpdateAvailable
		
		/// A minor update was found (includes which version). Minor update is
		/// e.g. 1.0.1 -> 1.0.2.
		case minorUpdateAvailable(version: String)
		
		/// A major update was found (includes which version). Major update is
		/// either 1.x -> 2.x, or 1.0 -> 1.1. When such an update is discovered,
		/// you should not allow the user to use the app.
		case majorUpdateAvailable(version: String)
		
	}
	
	/// AppStore URL. It is automatically retrieved during the update check.
	public private(set) var appStoreURL: URL?
	
	/// Download center used by the checker.
	private let _downloadCenter: XUDownloadCenter = XUDownloadCenter(identifier: "XUUpdateChecker")
	
	
	/// Checks for updates synchronously and returns the result.
	private func _checkForUpdates() -> Result {
		guard let obj = self._downloadCenter.downloadJSONDictionary(at: URL(string: "https://itunes.apple.com/lookup?bundleId=" + XUAppSetup.applicationIdentifier)) else {
			return .failure
		}
		
		guard let version = obj.string(forKeyPath: "[results][0][version]") else {
			return .failure
		}
		
		if let urlString = obj.string(forKeyPath: "[results][0][trackViewUrl]") {
			self.appStoreURL = URL(string: urlString)
		}
		
		let currentVersion = XUAppSetup.applicationVersionNumber
		if version == currentVersion {
			return .noUpdateAvailable
		}
		
		let appStoreVersionComponents = version.components(separatedBy: ".")
		let currentVersionComponents = currentVersion.components(separatedBy: ".")
		
		// 1.x -> 2.x
		if appStoreVersionComponents[0] != currentVersionComponents[0] {
			return .majorUpdateAvailable(version: version)
		}
		
		// The version of the current build is e.g. just "1", without ".0". While
		// this is a bad practice, it can happen.
		if currentVersionComponents.count == 1 {
			if appStoreVersionComponents[1] != "0" {
				return .majorUpdateAvailable(version: version)
			} else {
				return .minorUpdateAvailable(version: version)
			}
		}
		
		// 1.0.x -> 1.1.x
		if appStoreVersionComponents[1] != currentVersionComponents[1] {
			return .majorUpdateAvailable(version: version)
		}
		
		return .minorUpdateAvailable(version: version)
	}
	
	
	/// Check for update and calls the completionHandler with result. The completion
	/// handler is guaranteed to be called on the main thread.
	public func checkForUpdates(completionHandler: @escaping (Result) -> Void) {
		XU_PERFORM_BLOCK_ASYNC {
			let result = self._checkForUpdates()
			XU_PERFORM_BLOCK_ON_MAIN_THREAD {
				completionHandler(result)
			}
		}
	}
	
	public init() {}
	
	/// Opens the AppStore. This is based on the information it gets back from
	/// the bundle ID lookup during update checking. It terminates the app as well.
	public func openAppStoreAndTerminate() {
		if let appStoreURL = self.appStoreURL {
			#if os(macOS)
				NSWorkspace.shared.open(appStoreURL)
			#else
				UIApplication.shared.open(appStoreURL, options: [:], completionHandler: nil)
			#endif
		}
		
		exit(1)
	}
	
}
