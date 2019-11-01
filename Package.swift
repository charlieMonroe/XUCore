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
		],
		dependencies: [],
		targets: [
			.target(name: "XUCoreMobile")
		]
	)

#endif
