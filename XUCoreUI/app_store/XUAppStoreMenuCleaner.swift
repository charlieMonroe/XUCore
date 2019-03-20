//
//  FCAppStoreMenuCleaner.swift
//  XUCore
//
//  Created by Charlie Monroe on 11/21/15.
//  Copyright © 2015 Charlie Monroe Software. All rights reserved.
//

import Foundation

public struct XUAppStoreMenuCleaner {
	
	/// Use this tag (127) for tagging menu items that should be removed by the methods
	/// below.
	public static let tagForAppStoreOnlyMenuItems: Int = 127
	
	/// Removes menu items with tag tagForAppStoreOnlyMenuItems.
	public static func cleanMenu(_ menu: NSMenu) {
		for i in (0 ..< menu.numberOfItems).reversed() {
			guard let menuItem = menu.item(at: i) else {
				continue
			}
			
			if menuItem.tag == 127 {
				menu.removeItem(at: i)
				continue
			}
			
			if let submenu = menuItem.submenu {
				self.cleanMenu(submenu)
			}
		}
	}
	
	/// Calls XUCleanMenu on main menu.
	public static func cleanMainMenu() {
		if let menu = NSApp.mainMenu {
			self.cleanMenu(menu)
		}
	}

}
