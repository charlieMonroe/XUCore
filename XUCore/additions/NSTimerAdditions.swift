//
//  NSTimerAdditions.swift
//  XUCore
//
//  Created by Charlie Monroe on 11/11/15.
//  Copyright © 2015 Charlie Monroe Software. All rights reserved.
//

import Foundation

/// Private class that is for holding the timer fire block.
private class __XUTimerBlockHolder {
	
	let timerBlock: Timer.XUTimerBlock
	
	init(timerBlock: @escaping Timer.XUTimerBlock) {
		self.timerBlock = timerBlock
	}
	
}

public extension Timer {
	
	public typealias XUTimerBlock = (Timer) -> Void
	
	@objc fileprivate class func __executionMethod(_ timer: Timer) {
		let holder = timer.userInfo as! __XUTimerBlockHolder
		holder.timerBlock(timer)
	}
	
	public class func scheduledTimerWithTimeInterval(_ seconds: TimeInterval, repeats: Bool, usingBlock fireBlock: @escaping XUTimerBlock) -> Timer {
		return self.scheduledTimer(timeInterval: seconds, target: self, selector: #selector(Timer.__executionMethod(_:)), userInfo: __XUTimerBlockHolder(timerBlock: fireBlock), repeats: repeats)
	}
	
	public class func timerWithTimeInterval(_ seconds: TimeInterval, repeats: Bool, usingBlock fireBlock: @escaping XUTimerBlock) -> Timer {
		return self.init(timeInterval: seconds, target: self, selector: #selector(Timer.__executionMethod(_:)), userInfo: __XUTimerBlockHolder(timerBlock: fireBlock), repeats: repeats)
	}
	
}


