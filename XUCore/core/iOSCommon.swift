//
//  iOSCommon.swift
//  XUCore
//
//  Created by Charlie Monroe on 11/21/15.
//  Copyright © 2015 Charlie Monroe Software. All rights reserved.
//
//  This file contains several functions that help to maintain a cleaner code.
//

import UIKit

/// This value is set to true if the current device is an iPhone.
public let XURunningPhoneDevice: Bool = (UIDevice.currentDevice().userInterfaceIdiom == .Phone)

/// This value contains the iOS version - e.g. iOS 8.2.1 -> 8, iOS 9.1 -> 9.
public let XUSystemMajorVersion: Int = NSProcessInfo.processInfo().operatingSystemVersion.majorVersion
