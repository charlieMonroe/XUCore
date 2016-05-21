//
//  XUAbstract.swift
//  DownieCore
//
//  Created by Charlie Monroe on 8/12/15.
//  Copyright © 2015 Charlie Monroe Software. All rights reserved.
//

import Foundation

/** Throws an abstraction exception. */
@noreturn public func XUThrowAbstractException(additionalInformation: String = "", file: String = #file.componentsSeparatedByString("/").last!, line: Int = #line, method: String = #function) {
	
	let reason = "XUAbstractException: [\(file):\(line) \(method)] \(additionalInformation)"
	NSException(name: "XUAbstractExceptionName", reason: reason, userInfo: nil).raise()
	abort()
}

