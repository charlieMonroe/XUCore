//
//  NSToolbarAdditions.swift
//  XUCore
//
//  Created by Charlie Monroe on 11/8/15.
//  Copyright © 2015 Charlie Monroe Software. All rights reserved.
//

import Foundation

public extension NSToolbar {
	
	/// Returns item with identifier.
	public func itemWithIdentifier(_ identifier: String) -> NSToolbarItem? {
		return self.items.find({ $0.itemIdentifier == identifier })
	}
	
}
