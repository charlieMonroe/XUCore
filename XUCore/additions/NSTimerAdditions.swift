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
	
	let timerBlock: NSTimer.XUTimerBlock
	
	init(timerBlock: NSTimer.XUTimerBlock) {
		self.timerBlock = timerBlock
	}
	
}

public extension NSTimer {
	
	public typealias XUTimerBlock = (NSTimer) -> Void
	
	@objc private class func __executionMethod(timer: NSTimer) {
		let holder = timer.userInfo as! __XUTimerBlockHolder
		holder.timerBlock(timer)
	}
	
	public class func scheduledTimerWithTimeInterval(seconds: NSTimeInterval, repeats: Bool, usingBlock fireBlock: XUTimerBlock) -> NSTimer {
		return self.scheduledTimerWithTimeInterval(seconds, target: self, selector: #selector(NSTimer.__executionMethod(_:)), userInfo: __XUTimerBlockHolder(timerBlock: fireBlock), repeats: repeats)
	}
	
	public class func timerWithTimeInterval(seconds: NSTimeInterval, repeats: Bool, usingBlock fireBlock: XUTimerBlock) -> NSTimer {
		return self.init(timeInterval: seconds, target: self, selector: #selector(NSTimer.__executionMethod(_:)), userInfo: __XUTimerBlockHolder(timerBlock: fireBlock), repeats: repeats)
	}
	
}


