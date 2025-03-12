//
//  XUCompoundError.swift
//  XUCore
//
//  Created by Charlie Monroe on 6/20/16.
//  Copyright © 2016 Charlie Monroe Software. All rights reserved.
//

import Foundation

/// An error subclass that may contain multiple errors.
public final class XUCompoundError: NSError, @unchecked Sendable {
	
	private let _failureReason: String
	
	/// Errors of the compound error.
	public let errors: [NSError]
	
	/// Inits with errors. Will return nil if the erros array is empty.
	public init?(domain: String, code: Int = 0, localizedFailureReason: String, andErrors errors: [NSError]) {
		if errors.isEmpty {
			return nil
		}
		
		self.errors = errors
		
		_failureReason = localizedFailureReason
		
		super.init(domain: domain, code: code, userInfo: [
			NSLocalizedDescriptionKey: localizedFailureReason
		])
	}
	
	public required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	public override var localizedFailureReason: String? {
		_failureReason
	}
	
	/// This class automatically provides a localized description by putting
	/// together failure reasons of self.errors.
	public override var localizedDescription: String {
		#if os(iOS)
		// This is for iOS compatibility with UIAlertControllerAdditions.
		_informativeText
		#else
		_failureReason
		#endif
	}
	
	public override var localizedRecoverySuggestion: String? {
		return _informativeText
	}
	
	private var _informativeText: String {
		let maximum = 20
		
		let failureReasons = self.errors.prefix(maximum).map({ $0.localizedFailureReason ?? $0.localizedDescription }).compacted()
		var result = "• " + failureReasons.joined(separator: "\n• ")
		if self.errors.count > maximum {
			let overlap = self.errors.count - maximum
			if overlap == 1 {
				result += "• " + (self.errors[maximum].localizedFailureReason ?? self.errors[maximum].localizedDescription)
			} else {
				result += "\n• " + Localized("... and %li other errors.", overlap)
			}
		}
		return result
	}
	
}
