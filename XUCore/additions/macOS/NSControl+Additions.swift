//
//  NSControl+Additions.swift
//  XUCore
//
//  Created by Charlie Monroe on 8/2/17.
//  Copyright © 2017 Charlie Monroe Software. All rights reserved.
//

import AppKit

public extension NSControl.StateValue {
	
	/// Returns true if self == .off.
	var isOff: Bool {
		return self == .off
	}
	
	/// Returns true if self == .on.
	var isOn: Bool {
		return self == .on
	}
	
}

