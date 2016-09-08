//
//  XUHardwareInfo.swift
//  XUCore
//
//  Created by Charlie Monroe on 11/22/15.
//  Copyright © 2015 Charlie Monroe Software. All rights reserved.
//

import Foundation
import IOKit

/// This class contains various methods and properties for obtaining information
/// about the underlying hardware.
open class XUHardwareInfo: NSObject {
	
	/// Shared hardware info object.
	open static let sharedHardwareInfo = XUHardwareInfo()
	
	/// Returns the serial number of the computer.
	open let serialNumber: String = {
		let serviceName = "IOPlatformExpertDevice"
		let platformExpert = IOServiceGetMatchingService(kIOMasterPortDefault, IOServiceMatching(serviceName))
		let serialNumberAsCFString = IORegistryEntryCreateCFProperty(platformExpert, kIOPlatformSerialNumberKey as CFString!, kCFAllocatorDefault, 0)
		let serialNumber = serialNumberAsCFString?.takeUnretainedValue() as! String
		IOObjectRelease(platformExpert);
		return serialNumber
	}()
	
}
