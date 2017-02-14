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

