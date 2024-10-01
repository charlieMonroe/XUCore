//
//  XUHardwareInfo.swift
//  XUCore
//
//  Created by Charlie Monroe on 11/22/15.
//  Copyright © 2015 Charlie Monroe Software. All rights reserved.
//

import Foundation

#if os(macOS)
	import AppKit
	import IOKit
#else
	import UIKit
#endif

private extension XUPreferences.Key {
	static let generatedSerialNumber = XUPreferences.Key("_XUGeneratedSerialNumber")
}

private extension XUPreferences {
	
	var generatedSerialNumber: String? {
		get {
			return self.value(for: .generatedSerialNumber)
		}
		nonmutating set {
			self.set(value: newValue, forKey: .generatedSerialNumber)
		}
	}
	
}

/// This struct contains various methods and properties for obtaining information
/// about the underlying hardware.
public struct XUHardwareInfo {
	
	/// Architecture of the CPU.
	public enum Architecture: String {
		case arm64 = "ARM64"
		case x64 = "x64"
		case unknown = "Unknown"
	}
	
	
	/// Shared hardware info object.
	public static let shared: XUHardwareInfo = XUHardwareInfo()
	
	/// For some devices (e.g. with logic board replacement), we
	/// are unable to get device serial number. This is a workaround
	/// which generates and stores a fixed UUID.
	private static func _generatedUUID() -> String {
		guard let generatedSerial = XUPreferences.shared.generatedSerialNumber else {
			let newSerial = "XUGeneratedSerialNumber_" + UUID().uuidString.md5Digest
			
			XUPreferences.shared.perform { prefs in
				prefs.generatedSerialNumber = newSerial
			}
			
			return newSerial
		}
		
		return generatedSerial
	}
	
	/// Returns architecture (e.g. x64, ARM64, etc.).
	public var architecture: Architecture = {
		#if os(iOS)
			// We're not running anything else on iOS at this moment.
			return .arm64
		#else
			switch NSRunningApplication.current.executableArchitecture {
			case NSBundleExecutableArchitectureX86_64:
				return .x64
			case NSBundleExecutableArchitectureARM64:
				return .arm64
			default:
				return .unknown
			}
		#endif
	}()
	
	/// Returns architecture name (e.g. x64, ARM64, etc.).
	public var architectureName: String {
		return self.architecture.rawValue
	}
	
	/// Returns the serial number of the device. On iOS this is
	/// UIDevice.current.identifierForVendor.
	public let serialNumber: String = {
		#if os(iOS)
			return UIDevice.current.identifierForVendor?.uuidString ?? XUHardwareInfo._generatedUUID()
		#else
			let serviceName = "IOPlatformExpertDevice"
			let platformExpert = IOServiceGetMatchingService(kIOMasterPortDefault, IOServiceMatching(serviceName))
			let serialNumberAsCFString = IORegistryEntryCreateCFProperty(platformExpert, kIOPlatformSerialNumberKey as CFString, kCFAllocatorDefault, 0)
			guard let serialNumber = serialNumberAsCFString?.takeUnretainedValue() as? String else {
				return XUHardwareInfo._generatedUUID()
			}
			
			IOObjectRelease(platformExpert);
			return serialNumber
		#endif
	}()
	
}
