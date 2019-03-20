//
//  XUMath.swift
//  XUCore
//
//  Created by Charlie Monroe on 11/21/15.
//  Copyright © 2015 Charlie Monroe Software. All rights reserved.
//

import Foundation

extension BinaryFloatingPoint {
	
	/// Returns degrees converted to radian.
	public func convertDegreesToRadian() -> Self {
		return self * (Self.pi / 180.0)
	}
	
}

