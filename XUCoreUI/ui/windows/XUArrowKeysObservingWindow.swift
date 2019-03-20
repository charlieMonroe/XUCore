//
//  XUArrowKeysObservingWindow.swift
//  XUCore
//
//  Created by Charlie Monroe on 1/22/16.
//  Copyright © 2016 Charlie Monroe Software. All rights reserved.
//

import Foundation

/// The window only overrides the sendEvent(_) method and distributes arrow
/// key down events to the methods.
open class XUArrowKeysObservingWindow: NSWindow {
	
	open func arrowKeyDownPressed(_ event: NSEvent) {
		super.sendEvent(event)
	}
	
	open func arrowKeyLeftPressed(_ event: NSEvent) {
		super.sendEvent(event)
	}
	
	open func arrowKeyRightPressed(_ event: NSEvent) {
		super.sendEvent(event)
	}
	
	open func arrowKeyUpPressed(_ event: NSEvent) {
		super.sendEvent(event)
	}
	
	open override func sendEvent(_ theEvent: NSEvent) {
		if theEvent.type == .keyDown {
			switch theEvent.keyCode {
			case XUKeyCode.keyUp.rawValue:
				self.arrowKeyUpPressed(theEvent)
				return
			case XUKeyCode.keyDown.rawValue:
				self.arrowKeyDownPressed(theEvent)
				return
			case XUKeyCode.keyRight.rawValue:
				self.arrowKeyRightPressed(theEvent)
				return
			case XUKeyCode.keyLeft.rawValue:
				self.arrowKeyLeftPressed(theEvent)
				return
			default:
				break
			}
		}
		super.sendEvent(theEvent)
	}
	
}
