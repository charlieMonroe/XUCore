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
public class XUHardwareInfo: NSObject {
	
	/// Shared hardware info object.
	public static let sharedHardwareInfo = XUHardwareInfo()
	
	/// Returns the serial number of the computer.
	public let serialNumber: String = {
		let serviceName = "IOPlatformExpertDevice"
		let platformExpert = IOServiceGetMatchingService(kIOMasterPortDefault, IOServiceMatching(serviceName))
		let serialNumberAsCFString = IORegistryEntryCreateCFProperty(platformExpert, kIOPlatformSerialNumberKey, kCFAllocatorDefault, 0)
		let serialNumber = serialNumberAsCFString.takeUnretainedValue() as! String
		IOObjectRelease(platformExpert);
		return serialNumber
	}()
	
}
