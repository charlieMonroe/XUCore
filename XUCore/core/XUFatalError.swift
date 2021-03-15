//
//  XUAbstract.swift
//  DownieCore
//
//  Created by Charlie Monroe on 8/12/15.
//  Copyright © 2015 Charlie Monroe Software. All rights reserved.
//

import Foundation

public protocol XUFatalErrorObserver {
	
	func fatalErrorDidOccur(with reason: String)
	
}

public struct XUFatalErrorObservation {
	
	fileprivate static var _observers: [XUFatalErrorObserver] = []
	
	/// Adds an observer for XUFatalError.
	public static func addObserver(_ observer: XUFatalErrorObserver) {
		_observers.append(observer)
	}
	
}


/// The advantage of this is that unlike fatalError, this will include file,
/// line and method in the reason of fatalError.
public func XUFatalError(_ additionalInformation: String = "", file: String = #file, line: Int = #line, method: String = #function) -> Never  {
	let reason = "XUFatalError: [\(file.components(separatedBy: "/").last!):\(line) \(method)] \(additionalInformation)"
	XULogStacktrace(reason)
	
	XUFatalErrorObservation._observers.forEach({ $0.fatalErrorDidOccur(with: reason) })
	
	fatalError(reason)
}

/// Similar to XUFatalError, this is observable and on macOS hooked up to
/// XUExceptionReporter.
public func XUAssert(_ assertion: @autoclosure () -> Bool, _ additionalInformation: String = "undefined", file: String = #file, line: Int = #line, method: String = #function) {
	guard assertion() else {
		XUFatalError("Failed assertion \(additionalInformation).", file: file, line: line, method: method)
	}
}

/// Asserts that this is invoked on main thread. See XUAssert.
public func XUAssertMainThread(_ additionalInformation: String = "undefined", file: String = #file, line: Int = #line, method: String = #function) {
	XUAssert(Thread.isMainThread, additionalInformation, file: file, line: line, method: method)
}

