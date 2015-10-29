//
//  XUAbstract.swift
//  DownieCore
//
//  Created by Charlie Monroe on 8/12/15.
//  Copyright © 2015 Charlie Monroe Software. All rights reserved.
//

import Foundation

/** Throws an abstraction exception. */
@noreturn public func XUThrowAbstractException(file: String = __FILE__, line: Int = __LINE__, method: String = __FUNCTION__) {
	NSException(name: "XUAbstractExceptionName", reason: "[\(file):\(line) \(method)]", userInfo: nil).raise()
	abort()
}

