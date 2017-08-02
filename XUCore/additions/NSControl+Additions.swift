//
//  NSControl+Additions.swift
//  XUCore
//
//  Created by Charlie Monroe on 8/2/17.
//  Copyright © 2017 Charlie Monroe Software. All rights reserved.
//

import AppKit

public extension NSControl.StateValue {
	
	/// Returns true if self == .on.
	public var isOn: Bool {
		return self == .onState || self == .on
	}
	
}

