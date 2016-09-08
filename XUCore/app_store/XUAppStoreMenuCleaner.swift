//
//  FCAppStoreMenuCleaner.swift
//  XUCore
//
//  Created by Charlie Monroe on 11/21/15.
//  Copyright © 2015 Charlie Monroe Software. All rights reserved.
//

import Foundation

/// Use this tag (127) for tagging menu items that should be removed by the methods
/// below.
public let kXUMenuItemAppStoreTag = 127

/// Removes menu items with tag kXUMenuItemAppStoreTag.
public func XUCleanMenu(_ menu: NSMenu) {
	for i in (0 ..< menu.numberOfItems).reversed() {
		guard let menuItem = menu.item(at: i) else {
			continue
		}
		
		if menuItem.tag == 127 {
			menu.removeItem(at: i)
			continue
		}
		
		if let submenu = menuItem.submenu {
			XUCleanMenu(submenu)
		}
	}
}


/// Calls XUCleanMenu on main menu.
public func XUCleanMenuBar() {
	if let menu = NSApp.mainMenu {
		XUCleanMenu(menu)
	}
}


open class XUMenuBarCleaner: NSObject {
	
	/// Should be only called from ObjC. To be removed soon.
	open class func cleanMenuBar() {
		XUCleanMenuBar()
	}
	
}

