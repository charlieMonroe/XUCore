//
//  XUCompoundError.swift
//  XUCore
//
//  Created by Charlie Monroe on 6/20/16.
//  Copyright © 2016 Charlie Monroe Software. All rights reserved.
//

import Foundation

/// An error subclass that may contain multiple errors.
public class XUCompoundError: NSError {
	
	/// Errors of the compound error.
	public let errors: [NSError]
	
	/// Inits with errors. Will return nil if the erros array is empty.
	public init?(domain: String, code: Int = 0, localizedFailureReason: String, andErrors errors: [NSError]) {
		if errors.isEmpty {
			return nil
		}
		
		self.errors = errors
		
		super.init(domain: domain, code: code, userInfo: [
			NSLocalizedFailureReasonErrorKey: localizedFailureReason
		])
	}
	
	public required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	/// This class automatically provides a localized description by putting
	/// together failure reasons of self.errors.
	public override var localizedDescription: String {
		let failureReasons = self.errors.map({ $0.localizedFailureReason }).flatMap({ $0 })
		return failureReasons.joinWithSeparator("\n• ")
	}
	
}
