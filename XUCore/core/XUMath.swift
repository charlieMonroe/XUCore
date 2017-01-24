//
//  XUMath.swift
//  XUCore
//
//  Created by Charlie Monroe on 11/21/15.
//  Copyright © 2015 Charlie Monroe Software. All rights reserved.
//

#if os(iOS)
	import UIKit
#else
	import AppKit
#endif

/// Returns degrees converted to radian.
public func XUDegreesToRadian(_ degrees: CGFloat) -> CGFloat {
	return degrees * CGFloat(CGFloat.pi / 180.0)
}

