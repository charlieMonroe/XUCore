//
//  XUUIBridge.swift
//  XUCore
//
//  Created by Charlie Monroe on 1/11/16.
//  Copyright © 2016 Charlie Monroe Software. All rights reserved.
//

/// A type that defines a native view on the platform. On OS X, it's NSView,
/// UIView on iOS.
#if os(iOS)
	import UIKit
	public typealias __XUBridgedView = UIView
#else
	import AppKit
	public typealias __XUBridgedView = NSView
#endif


