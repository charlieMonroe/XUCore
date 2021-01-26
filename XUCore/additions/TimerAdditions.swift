//
//  NSTimerAdditions.swift
//  XUCore
//
//  Created by Charlie Monroe on 11/11/15.
//  Copyright © 2015 Charlie Monroe Software. All rights reserved.
//

import Foundation

public extension Timer {
	
	@available(*, deprecated, message: "Use system function.")
	typealias TimerBlock = (Timer) -> Void
	
	@discardableResult
	@available(*, deprecated, message: "Use system function.", renamed: "scheduledTimer(withTimeInterval:repeats:block:)")
	class func scheduledTimer(timeInterval seconds: TimeInterval, repeats: Bool, usingBlock fireBlock: @escaping TimerBlock) -> Timer {
		return self.scheduledTimer(withTimeInterval: seconds, repeats: repeats, block: fireBlock)
	}
	
	@available(*, deprecated, message: "Use system-provided initializer.")
	class func timer(timeInterval seconds: TimeInterval, repeats: Bool, usingBlock fireBlock: @escaping TimerBlock) -> Timer {
		return Timer(timeInterval: seconds, repeats: repeats, block: fireBlock)
	}
	
}


