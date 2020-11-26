//
//  XUApplicationState.swift
//  XUCore
//
//  Created by Charlie Monroe on 8/15/16.
//  Copyright © 2016 Charlie Monroe Software. All rights reserved.
//

import Foundation

#if os(macOS)
	import AppKit // For NSApplication
#endif

/// The exception handler can have an application state provider which should
/// include a single method. See its docs. You can set the current application
/// state provider on XUApplicationSetup.
public protocol XUApplicationStateProvider {
	
	/// Return a string that describes the application's state. E.g. if there
	/// is any network activity going on, if any documents are open, etc.
	func provideApplicationState() -> String
	
}

/// Item depicting a particular part of the application state.
/// @see XUBasicApplicationStateProvider.stateItems
public struct XUApplicationStateItem {
	
	/// Name of the item. E.g. "Running since".
	public let name: String
	
	/// If true, when the application state items are transformed into a string,
	/// there is an extra new line after this block.
	public let requiresAdditionalTrailingNewLine: Bool
	
	/// Value of the item. E.g. "May 14".
	public let value: String
	
	/// Designated initializer.
	public init(name: String, value: String, requiresAdditionalTrailingNewLine: Bool = false) {
		self.name = name
		self.value = value
		self.requiresAdditionalTrailingNewLine = requiresAdditionalTrailingNewLine
	}
	
}


/// Basic application state provider. Maintains some information about the application
/// and provides an easy way to supply additional information in a key-value
/// manner.
open class XUBasicApplicationStateProvider: XUApplicationStateProvider {
	
	/// Automatically initialized to Date(), providing how long has the app been
	/// running.
	public let launchTime: Date = Date()
	
	public var memoryUsage: UInt64 {
		let basicInfoCount = MemoryLayout<mach_task_basic_info_data_t>.size / MemoryLayout<natural_t>.size
		var outCount = mach_msg_type_number_t(basicInfoCount)
		
		var info = mach_task_basic_info()
		
		// call task_info - note extra UnsafeMutablePointer(...) call
		let status = withUnsafeMutablePointer(to: &info) {
			$0.withMemoryRebound(to: integer_t.self, capacity: 1, {
				task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &outCount)
			})
		}
		
		guard status == KERN_SUCCESS else {
			XULog("Can't get memory usage.")
			return 0
		}
		
		return info.resident_size
	}
	
	private class func _calculateBinaryMD5(for bundle: Bundle) -> String {
		guard let executableURL = bundle.executableURL else {
			return "nil"
		}
		
		guard let data = try? Data(contentsOf: executableURL) else {
			return "nil"
		}
		
		return data.md5Digest
	}
	
	/// Creates an application state that contains MD5s of the main binary and
	/// framework binaries.
	public class func createBinaryMD5sApplicationStateItem() -> XUApplicationStateItem {
		let frameworkURLs = FileManager.default.contentsOfDirectory(at: Bundle.main.bundleURL.appendingPathComponents("Contents", "Frameworks")).filter({ $0.pathExtension == "framework" })
		let frameworkBundles = frameworkURLs.compactMap(Bundle.init(url:)).sorted(by: { $0.bundleURL.lastPathComponent < $1.bundleURL.lastPathComponent })
		let otherBinaryMD5s = frameworkBundles.map({ "\t\($0.bundleURL.lastPathComponent): \(self._calculateBinaryMD5(for: $0))" }).joined(separator: "\n")
		return XUApplicationStateItem(name: "Binary MD5s", value: "\n\tMain: \(self._calculateBinaryMD5(for: Bundle.main))\n\(otherBinaryMD5s)", requiresAdditionalTrailingNewLine: true)
	}
	
	/// Returns state values. By default, this contains run-time, window list
	/// including names and perhaps in the future additional values. Override
	/// this var and append your values to what super returns.
	open var stateItems: [XUApplicationStateItem] {
		var stateItems: [XUApplicationStateItem] = [
			XUApplicationStateItem(name: "Version", value: "\(XUAppSetup.applicationVersionNumber) (\(XUAppSetup.applicationBuildNumber))"),
			XUApplicationStateItem(name: "OS Version", value: ProcessInfo().operatingSystemVersion.versionString),
			XUApplicationStateItem(name: "Locale", value: Locale.current.identifier),
			XUApplicationStateItem(name: "Beta", value: "\(XUAppSetup.isBetaBuild)"),
			XUApplicationStateItem(name: "Build Type", value: XUAppSetup.buildType.rawValue),
			XUApplicationStateItem(name: "Memory Usage", value: ByteCountFormatter.string(fromByteCount: Int64(self.memoryUsage), countStyle: .memory)),
			XUApplicationStateItem(name: "Run Time", value: XUTime.timeString(from: Date.timeIntervalSinceReferenceDate - self.launchTime.timeIntervalSinceReferenceDate)),
			XUApplicationStateItem(name: "Launch Count", value: "\(XUPreferences.shared.launchCount)")
		]
		
		if XUPreferences.isApplicationUsingPreferences, let reflectablePreferences = XUPreferences.shared as? XUReflectablePreferences {
			stateItems.append(reflectablePreferences.preferencesStateItem)
		}
		
		let hashItem = XUBasicApplicationStateProvider.createBinaryMD5sApplicationStateItem()
		stateItems.append(XUApplicationStateItem(name: "Binary Hashes Combined", value: hashItem.value.md5Digest))
		stateItems.append(hashItem)
		
		#if os(macOS)
			let windows = NSApp.windows.map({ "\t\($0) - \($0.title)" }).joined(separator: "\n")
			stateItems.append(XUApplicationStateItem(name: "Window List", value: "\n\(windows)", requiresAdditionalTrailingNewLine: true))
		#endif
		
		return stateItems
	}
	
	public init() {}
	
	open func provideApplicationState() -> String {
		return self.stateItems.map({
			var itemString = "\($0.name): \($0.value)"
			if $0.requiresAdditionalTrailingNewLine {
				itemString += "\n"
			}
			return itemString
		}).joined(separator: "\n")
	}
	
}

