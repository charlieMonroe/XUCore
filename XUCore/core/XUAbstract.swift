//
//  XUAbstract.swift
//  DownieCore
//
//  Created by Charlie Monroe on 8/12/15.
//  Copyright © 2015 Charlie Monroe Software. All rights reserved.
//

import Foundation

/// The advantage of this is that unlike fatalError, this will include file,
/// line and method in the reason of fatalError.
public func XUFatalError(_ additionalInformation: String = "", file: String = #file.components(separatedBy: "/").last!, line: Int = #line, method: String = #function) -> Never  {
	
	let reason = "XUFatalError: [\(file):\(line) \(method)] \(additionalInformation)"
	fatalError(reason)
}

/// Throws an abstraction exception.
///
/// Historically, this really threw an exception and was meant for abstract
/// method implementations. Now it just calls fatalError().
@available(*, deprecated, renamed: "XUFatalError")
public func XUThrowAbstractException(_ additionalInformation: String = "", file: String = #file.components(separatedBy: "/").last!, line: Int = #line, method: String = #function) -> Never  {
	
	let reason = "XUAbstractException: [\(file):\(line) \(method)] \(additionalInformation)"
	fatalError(reason)
}



