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
	
	let timerBlock: Timer.TimerBlock
	
	init(timerBlock: @escaping Timer.TimerBlock) {
		self.timerBlock = timerBlock
	}
	
}

public extension Timer {
	
	public typealias TimerBlock = (Timer) -> Void
	
	@objc private class func __executionMethod(_ timer: Timer) {
		let holder = timer.userInfo as! __XUTimerBlockHolder
		holder.timerBlock(timer)
	}
	
	@discardableResult
	public class func scheduledTimer(timeInterval seconds: TimeInterval, repeats: Bool, usingBlock fireBlock: @escaping TimerBlock) -> Timer {
		return self.scheduledTimer(timeInterval: seconds, target: self, selector: #selector(Timer.__executionMethod(_:)), userInfo: __XUTimerBlockHolder(timerBlock: fireBlock), repeats: repeats)
	}
	
	public class func timer(timeInterval seconds: TimeInterval, repeats: Bool, usingBlock fireBlock: @escaping TimerBlock) -> Timer {
		return self.init(timeInterval: seconds, target: self, selector: #selector(Timer.__executionMethod(_:)), userInfo: __XUTimerBlockHolder(timerBlock: fireBlock), repeats: repeats)
	}
	
}


