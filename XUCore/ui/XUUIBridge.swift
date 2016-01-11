//
//  XUUIBridge.swift
//  XUCore
//
//  Created by Charlie Monroe on 1/11/16.
//  Copyright © 2016 Charlie Monroe Software. All rights reserved.
//

import Foundation

/// A type that defines a native view on the platform. On OS X, it's NSView,
/// UIView on iOS.
#if os(iOS)
	public typealias __XUBridgedView = UIView
#else
	public typealias __XUBridgedView = NSView
#endif


