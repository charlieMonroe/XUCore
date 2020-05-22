//
//  XUHardwareInfo.swift
//  XUCore
//
//  Created by Charlie Monroe on 11/22/15.
//  Copyright © 2015 Charlie Monroe Software. All rights reserved.
//

import Foundation
import IOKit
import XUCore

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
	
	/// Shared hardware info object.
	public static let shared: XUHardwareInfo = XUHardwareInfo()
	
	/// Returns the serial number of the computer.
	public let serialNumber: String = {
		let serviceName = "IOPlatformExpertDevice"
		let platformExpert = IOServiceGetMatchingService(kIOMasterPortDefault, IOServiceMatching(serviceName))
		let serialNumberAsCFString = IORegistryEntryCreateCFProperty(platformExpert, kIOPlatformSerialNumberKey as CFString, kCFAllocatorDefault, 0)
		guard let serialNumber = serialNumberAsCFString?.takeUnretainedValue() as? String else {
			guard let generatedSerial = XUPreferences.shared.generatedSerialNumber else {
				let newSerial = "XUGeneratedSerialNumber_" + UUID().uuidString.md5Digest
				
				XUPreferences.shared.perform { (prefs) in
					prefs.generatedSerialNumber = newSerial
				}
				
				return newSerial
			}
			
			return generatedSerial
		}
		
		IOObjectRelease(platformExpert);
		return serialNumber
	}()
	
}
