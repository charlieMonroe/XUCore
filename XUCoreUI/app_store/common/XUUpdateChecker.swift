//
//  XUUpdateChecker.swift
//  XUCore
//
//  Created by Charlie Monroe on 3/19/18.
//  Copyright © 2018 Charlie Monroe Software. All rights reserved.
//

import Foundation
import XUCore

#if os(macOS)
	import AppKit
#else
	import UIKit
#endif

/// This class handles checking for updates based on the app's bundle identifier.
/// As this check is done against the AppStore, the app must be distributed via
/// the AppStore. If the app is a trial and the infoDictionary of the main bundle
/// contains SUFeedURL value, the check is done against that.
public final class XUUpdateChecker {
	
	/// Version struct. Assumes that the version is in format 1.2.3.
	public struct Version: Codable, Comparable, Equatable {
		
		public static func < (lhs: XUUpdateChecker.Version, rhs: XUUpdateChecker.Version) -> Bool {
			guard lhs.major == rhs.major else {
				if lhs.major < rhs.major {
					return true
				} else {
					return false
				}
			}
			
			guard lhs.minor == rhs.minor else {
				if lhs.minor < rhs.minor {
					return true
				} else {
					return false
				}
			}
			
			return lhs.patch < rhs.patch
		}
		
		/// Returns version of the current app.
		public static let current: Version = Version(versionString: XUAppSetup.applicationVersionNumber)
		
		
		/// Major: [1].2.3
		public let major: Int
		
		/// Minor: 1.[2].3
		public let minor: Int
		
		/// Patch: 1.2.[3]
		public let patch: Int
		
		/// Returns a version string. It doesn't guarantee to equal to the one
		/// passed via .init(versionString:) as this is reconstructed from the
		/// integers.
		public var versionString: String {
			return "\(self.major).\(self.minor).\(self.patch)"
		}
		
		/// Default initializer.
		public init(major: Int, minor: Int, patch: Int = 0) {
			self.major = major
			self.minor = minor
			self.patch = patch
		}
		
		/// Initializes with a version string. Must be in format 1.2.3, where the
		/// patch number isn't required.
		public init(versionString: String) {
			let components = versionString.components(separatedBy: ".")
			assert(components.count <= 3)
			
			if components.count == 1 {
				self.init(major: components[0].integerValue, minor: 0)
			} else if components.count == 2 {
				self.init(major: components[0].integerValue, minor: components[1].integerValue)
			} else {
				self.init(major: components[0].integerValue, minor: components[1].integerValue, patch: components[2].integerValue)
			}
		}
		
	}
	
	
	/// Result of the version checking.
	public enum Result: Equatable {
		
		public static func ==(lhs: Result, rhs: Result) -> Bool {
			switch (lhs, rhs) {
			case (.failure, .failure):
				return true
			case (.noUpdateAvailable, .noUpdateAvailable):
				return true
			case (.minorUpdateAvailable(let v1), .minorUpdateAvailable(let v2)):
				return v1 == v2
			case (.majorUpdateAvailable(let v1), .majorUpdateAvailable(let v2)):
				return v1 == v2
			default:
				return false
			}
		}
		
		/// This indicates either no Internet connection or that the app is not
		/// on the AppStore yet, or some other issue occurred.
		case failure
		
		/// We are running the latest version.
		case noUpdateAvailable
		
		/// A minor update was found (includes which version). Minor update is
		/// e.g. 1.0.1 -> 1.0.2.
		case minorUpdateAvailable(version: Version)
		
		/// A major update was found (includes which version). Major update is
		/// either 1.x -> 2.x, or 1.0 -> 1.1. When such an update is discovered,
		/// you should not allow the user to use the app.
		case majorUpdateAvailable(version: Version)
		
		
		/// Returns a version associated with the result. Will return nil for `.failure`
		/// and `.noUpdateAvailable`.
		public var version: Version? {
			switch self {
			case .failure, .noUpdateAvailable:
				return nil
			case .majorUpdateAvailable(version: let version):
				return version
			case .minorUpdateAvailable(version: let version):
				return version
			}
		}
		
	}
	
	/// AppStore URL. It is automatically retrieved during the update check.
	public private(set) var appStoreURL: URL?
	
	/// Direct download URL for the update discovered in the Sparkle update feed.
	public private(set) var updateURL: URL?
	
	/// Download center used by the checker.
	private let _downloadCenter: XUDownloadCenter = XUDownloadCenter(identifier: "XUUpdateChecker")
	
	
	/// Checks for updates synchronously and returns the result.
	private func _checkForUpdatesAgainstAppStore() -> Result {
		guard let obj = _downloadCenter.downloadJSONDictionary(at: URL(string: "https://itunes.apple.com/lookup?bundleId=" + XUAppSetup.applicationIdentifier)) else {
			return .failure
		}
		
		guard let versionString = obj.string(forKeyPath: "[results][0][version]") else {
			return .failure
		}
		
		let appStoreVersion = Version(versionString: versionString)
		
		if let urlString = obj.string(forKeyPath: "[results][0][trackViewUrl]") {
			self.appStoreURL = URL(string: urlString)
		}
		
		let currentVersion = Version.current
		if appStoreVersion <= currentVersion {
			return .noUpdateAvailable
		}
		
		// 1.x -> 2.x
		if appStoreVersion.major != currentVersion.major {
			return .majorUpdateAvailable(version: appStoreVersion)
		}
		
		return .minorUpdateAvailable(version: appStoreVersion)
	}
	
	#if os(macOS)
	private func _checkForUpdatesAgainstSparkleFeed() -> Result {
		guard let feedURLString = Bundle.main.infoDictionary?["SUFeedURL"] as? String, let feedURL = URL(string: feedURLString) else {
			return .failure
		}
		
		guard let doc = _downloadCenter.downloadXMLDocument(at: feedURL) else {
			return .failure
		}
		
		let nodes = doc.nodes(forXPath: "rss/channel/item/enclosure")
		guard let newestNode = nodes.findMax({ $0.integerValue(ofAttributeNamed: "sparkle:version") }) else {
			return .noUpdateAvailable
		}
		
		if let url = newestNode.stringValue(ofAttributeNamed: "url").flatMap(URL.init(string:)) {
			self.updateURL = url
		}
		
		guard let versionString = newestNode.stringValue(ofAttributeNamed: "sparkle:shortVersionString") else {
			return .noUpdateAvailable
		}
		
		let remoteVersion = Version(versionString: versionString)
		let currentVersion = Version.current
		if remoteVersion <= currentVersion {
			return .noUpdateAvailable
		}
		
		// 1.x -> 2.x
		if remoteVersion.major != currentVersion.major {
			return .majorUpdateAvailable(version: remoteVersion)
		}
		
		return .minorUpdateAvailable(version: remoteVersion)
	}
	#endif
	
	
	/// Check for update and calls the completionHandler with result. The completion
	/// handler is guaranteed to be called on the main thread.
	public func checkForUpdates(completionHandler: @escaping (Result) -> Void) {
		DispatchQueue.global(qos: .default).async {
			let result: Result
			if XUAppSetup.buildType == .appStore {
				 result = self._checkForUpdatesAgainstAppStore()
			} else {
				#if os(macOS)
					result = self._checkForUpdatesAgainstSparkleFeed()
				#else
					XUFatalError()
				#endif
			}
			
			// As DispatchQueue dispatch doesn't work in case of e.g. modal dialogs,
			// we're using a little helper.
			let performer = XUThreadPerformer(action: {
				completionHandler(result)
			})
			performer.perform(on: .main)
		}
	}
	
	public init() {}
	
	/// Opens the AppStore. This is based on the information it gets back from
	/// the bundle ID lookup during update checking. It terminates the app as well.
	/// Only use it when you are running an AppStore version of the app.
	@available(iOSApplicationExtension, unavailable)
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
