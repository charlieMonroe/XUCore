//
//  XUAbstract.swift
//  DownieCore
//
//  Created by Charlie Monroe on 8/12/15.
//  Copyright © 2015 Charlie Monroe Software. All rights reserved.
//

import Foundation

/** Throws an abstraction exception. */
@noreturn public func XUThrowAbstractException(file: String = #file, line: Int = #line, method: String = #function) {
	NSException(name: "XUAbstractExceptionName", reason: "[\(file.componentsSeparatedByString("/").last!):\(line) \(method)]", userInfo: nil).raise()
	abort()
}

