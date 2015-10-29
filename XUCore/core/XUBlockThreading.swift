//
//  XUBlockThreading.swift
//  DownieCore
//
//  Created by Charlie Monroe on 10/25/15.
//  Copyright © 2015 Charlie Monroe Software. All rights reserved.
//

import Foundation

public func XU_PERFORM_BLOCK_ON_MAIN_THREAD(block: () -> Void) {
	if NSThread.isMainThread() {
		block()
	}else{
		dispatch_sync(dispatch_get_main_queue(), block)
	}
}

public func XU_PERFORM_BLOCK_ON_MAIN_THREAD_ASYNC(block: () -> Void) {
	if NSThread.isMainThread() {
		block()
	}else{
		dispatch_async(dispatch_get_main_queue(), block)
	}
}
