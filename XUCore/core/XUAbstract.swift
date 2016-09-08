//
//  XUAbstract.swift
//  DownieCore
//
//  Created by Charlie Monroe on 8/12/15.
//  Copyright © 2015 Charlie Monroe Software. All rights reserved.
//

import Foundation

/** Throws an abstraction exception. */
public func XUThrowAbstractException(_ additionalInformation: String = "", file: String = #file.components(separatedBy: "/").last!, line: Int = #line, method: String = #function) -> Never  {
	
	let reason = "XUAbstractException: [\(file):\(line) \(method)] \(additionalInformation)"
	NSException(name: NSExceptionName(rawValue: "XUAbstractExceptionName"), reason: reason, userInfo: nil).raise()
	abort()
}

