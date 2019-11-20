// swift-tools-version:5.1
//
//  Package.swift
//  XUCore
//
//  Created by Charlie Monroe on 7/14/19.
//  Copyright © 2019 Charlie Monroe Software. All rights reserved.
//

import PackageDescription

#if os(macOS)
let package = Package(
		name: "XUCore",
		platforms: [
			.macOS(.v10_11)
		],
		products: [
			.library(name: "XUCore", targets: ["XUCore"]),
			.library(name: "XUCoreUI", targets: ["XUCoreUI"])
		],
		dependencies: [],
		targets: [
			.target(name: "XUCore")
		]
	)
#else
let package = Package(
		name: "XUCore",
		platforms: [
			.iOS(.v11)
		],
		products: [
			.library(name: "XUCore", targets: ["XUCoreMobile"]),
			.library(name: "XUCoreUI", targets: ["XUCoreUI iOS"])
		],
		dependencies: [],
		targets: [
			.target(name: "XUCoreMobile")
		]
	)

#endif
