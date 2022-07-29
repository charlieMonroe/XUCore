//
//  XUExceptionCatcher+Swift.swift
//  XUCore
//
//  Created by Charlie Monroe on 2/14/17.
//  Copyright © 2017 Charlie Monroe Software. All rights reserved.
//

import Foundation

extension XUExceptionCatcher {
	
	/// An error that encapsulates an error.
	public struct ExceptionError: Error, @unchecked Sendable {
		
		/// Exception this error was created with.
		public let exception: NSException
		
	}
	
	/// This performs a block - if the block throws an exception, this exception
	/// is wrapped in ExceptionError and thrown.
	public class func performBlock<T>(_ block: () -> T) throws -> T {
		var exception: NSException?
		var result: T?
		self.perform({
			result = block()
		}) { exception = $0 }
		
		if let exc = exception {
			throw ExceptionError(exception: exc)
		}
		
		return result!
	}
	
}
