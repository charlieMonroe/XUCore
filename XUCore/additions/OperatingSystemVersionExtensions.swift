//
//  OperatingSystemVersionExtensions.swift
//  XUCore
//
//  Created by Charlie Monroe on 10/16/17.
//  Copyright © 2017 Charlie Monroe Software. All rights reserved.
//

import Foundation

extension OperatingSystemVersion {
	
	#if os(macOS)
	public static let ventura: OperatingSystemVersion = OperatingSystemVersion(majorVersion: 13)
	public static let monterey: OperatingSystemVersion = OperatingSystemVersion(majorVersion: 12)
	public static let bigSur: OperatingSystemVersion = OperatingSystemVersion(majorVersion: 11)
	#endif
	
	
	/// Returns true if the current OS version is higher than the development target version.
	///
	/// This does not mean that it will report true for macOS 12.4 if DT is 12.3, but it will report
	/// true on macOS 13.0.
	public var isFutureBetaVersion: Bool {
		guard let buildSystemVersionString = Bundle.main.infoDictionary?["DTPlatformVersion"] as? String else {
			// TBD - what to report here?
			XULog("Info dictionary doesn't contain DTPlatformVersion - \(Bundle.main.infoDictionary as Any)")
			return false
		}
		
		let parts = buildSystemVersionString.components(separatedBy: ".")
		guard parts.count < 4, parts.count >= 2 else {
			XULog("DTPlatformVersion is weird - \(Bundle.main.infoDictionary as Any)")
			return false
		}
		
		guard let major = Int(parts[0]), let minor = Int(parts[1]) else {
			XULog("DTPlatformVersion is weird, non-int parts - \(Bundle.main.infoDictionary as Any)")
			return true
		}
		
		let patch = parts.count == 3 ? (Int(parts[2]) ?? 0) : 0
		let buildSystemVersion = OperatingSystemVersion(majorVersion: major, minorVersion: minor, patchVersion: patch)
		
		// This is an ugly heuristic. Betas will have minor and patch 0 and we check for
		// versions above DT Platform. This kind of assumes the app being up-to-date all
		// the time...
		return self.majorVersion > buildSystemVersion.majorVersion && self.minorVersion == 0 && self.patchVersion == 0
	}
	
	/// Converts this version to a version string, such as "10.13.1".
	public var versionString: String {
		return "\(self.majorVersion).\(self.minorVersion).\(self.patchVersion)"
	}
	
	/// Convenience initializer that uses 0 for unspecified version parts.
	public init(majorVersion: Int, minorVersion: Int = 0) {
		self.init(majorVersion: majorVersion, minorVersion: minorVersion, patchVersion: 0)
	}
	
}
