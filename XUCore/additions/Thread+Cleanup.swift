//
//  Thread+Cleanup.swift
//  XUCore
//
//  Created by Charlie Monroe on 2/15/22.
//  Copyright © 2022 Charlie Monroe Software. All rights reserved.
//

import Foundation

extension Thread {
	
	private class Cleanups {
		
		var cleanups: [() -> Void] = []
		
		deinit {
			for cleanup in self.cleanups {
				cleanup()
			}
		}
		
	}
	
	/// Adds a block to be executed when the thread is being destroyed.
	public func addThreadCleanup(_ cleanup: @escaping () -> Void) {
		let cleanups: Cleanups
		if let existingCleanups = self.threadDictionary["__XUCleanups__"] as? Cleanups {
			cleanups = existingCleanups
		} else {
			cleanups = Cleanups()
			self.threadDictionary["__XUCleanups__"] = cleanups
		}
		
		cleanups.cleanups.append(cleanup)
	}
	
}
