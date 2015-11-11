//
//  NSOpenPanelAdditions.swift
//  XUCore
//
//  Created by Charlie Monroe on 11/8/15.
//  Copyright © 2015 Charlie Monroe Software. All rights reserved.
//

import Foundation

public extension NSOpenPanel {
	
	public func runModalOnMainThread() -> Int {
		var response = NSFileHandlingPanelCancelButton
		XU_PERFORM_BLOCK_ON_MAIN_THREAD { () -> Void in
			response = self.runModal()
		}
		
		return response
	}
	
}
