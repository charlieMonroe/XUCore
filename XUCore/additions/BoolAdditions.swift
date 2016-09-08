//
//  BoolAdditions.swift
//  XUCore
//
//  Created by Charlie Monroe on 1/13/16.
//  Copyright © 2016 Charlie Monroe Software. All rights reserved.
//

import Foundation

/// Adding &= operator for Bool.
public func &=(lhs: inout Bool, rhs: Bool) {
	lhs = lhs && rhs
}

/// Adding |= operator for Bool.
public func |=(lhs: inout Bool, rhs: Bool) {
	lhs = lhs || rhs
}
