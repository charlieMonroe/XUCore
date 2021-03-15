//
//  NSToolbarAdditions.swift
//  XUCore
//
//  Created by Charlie Monroe on 11/8/15.
//  Copyright © 2015 Charlie Monroe Software. All rights reserved.
//

import AppKit
import Foundation

public extension NSToolbar {
	
	/// Returns item with identifier.
	func item(withIdentifier identifier: NSToolbarItem.Identifier) -> NSToolbarItem? {
		return self.items.first(where: { $0.itemIdentifier == identifier })
	}
	
}
