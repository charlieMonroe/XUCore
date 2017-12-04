//
//  XUBundleUtilities.swift
//  XUCore
//
//  Created by Charlie Monroe on 11/30/15.
//  Copyright © 2015 Charlie Monroe Software. All rights reserved.
//

import Foundation

/// Unfortunately, Swift compiler sometimes has an issue compiling
/// NSBundle.mainBundle() and crashes. This can be easily solved by creating
/// an internal lazy-loaded variable such as this one.
@available(*, deprecated, message: "There is no reason to use this anymore.", renamed: "Bundle.main")
public let XUMainBundle = Bundle.main

