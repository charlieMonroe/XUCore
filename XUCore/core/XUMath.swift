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

extension BinaryFloatingPoint {
	
	/// Returns degrees converted to radian.
	public func convertDegreesToRadian() -> Self {
		return self * (Self.pi / 180.0)
	}
	
}


/// Returns degrees converted to radian.
@available(*, deprecated, message: "Use number.convertDegreesToRadian() instead.")
public func XUDegreesToRadian(_ degrees: CGFloat) -> CGFloat {
	return degrees * CGFloat(CGFloat.pi / 180.0)
}

