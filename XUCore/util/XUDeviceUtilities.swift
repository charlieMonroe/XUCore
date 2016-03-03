//
//  XUDeviceUtilities.swift
//  XUCore
//
//  Created by Charlie Monroe on 3/3/16.
//  Copyright © 2016 Charlie Monroe Software. All rights reserved.
//

import UIKit

/// Unfortunately, Swift compiler sometimes has an issue compiling
/// UIDevice.currentDevice() and crashes. This can be easily solved by creating
/// an internal lazy-loaded variable such as this one.
public let XUCurrentDevice = UIDevice.currentDevice()

