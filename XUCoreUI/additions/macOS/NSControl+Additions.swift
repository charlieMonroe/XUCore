//
//  NSControl+Additions.swift
//  XUCore
//
//  Created by Charlie Monroe on 8/2/17.
//  Copyright © 2017 Charlie Monroe Software. All rights reserved.
//

import AppKit

extension NSControl.StateValue {
	
	/// Returns true if self == .off.
	public var isOff: Bool {
		return self == .off
	}
	
	/// Returns true if self == .on.
	public var isOn: Bool {
		return self == .on
	}
	
	/// Reverses its state - i.e. on -> off, off -> on. If mixed, it stays mixed.
	public func reversed() -> NSControl.StateValue {
		switch self {
		case .on:
			return .off
		case .off:
			return .on
		default:
			return self
		}
	}
	
}

