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
public func XUFatalError(_ additionalInformation: String = "", file: String = #file, line: Int = #line, method: String = #function) -> Never  {
	let reason = "XUFatalError: [\(file.components(separatedBy: "/").last!):\(line) \(method)] \(additionalInformation)"
	XULogStacktrace(reason)
	
	#if os(macOS)
	if XUAppSetup.exceptionHandlerReportURL != nil {
		let exception = NSException(name: .internalInconsistencyException, reason: reason, userInfo: nil)
		
		var stackTraceString = ""
		if let provider = XUAppSetup.applicationStateProvider {
			XUExceptionCatcher.perform({
				stackTraceString += provider.provideApplicationState() + "\n\n"
			}, withCatchHandler: { (exception) in
				stackTraceString += "Failed to get application state - fetching it resulted in an exception \(exception).\n\n"
			})
		}
		
		stackTraceString += exception.description + "\n\n"
		
		let exceptionStackTrace = XUStacktraceString(from: exception)
		if !exceptionStackTrace.isEmpty {
			stackTraceString = exceptionStackTrace + "\n\n"
		}
		
		stackTraceString += XUStacktraceString()

		
		XUExceptionReporter.showReporter(for: exception, thread: .main, queue: .current, andStackTrace: stackTraceString)
	}
	#endif
	
	fatalError(reason)
}

