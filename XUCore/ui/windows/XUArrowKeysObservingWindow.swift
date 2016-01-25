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
public class XUArrowKeysObservingWindow: NSWindow {
	
	public func arrowKeyDownPressed(event: NSEvent) {
		super.sendEvent(event)
	}
	
	public func arrowKeyLeftPressed(event: NSEvent) {
		super.sendEvent(event)
	}
	
	public func arrowKeyRightPressed(event: NSEvent) {
		super.sendEvent(event)
	}
	
	public func arrowKeyUpPressed(event: NSEvent) {
		super.sendEvent(event)
	}
	
	public override func sendEvent(theEvent: NSEvent) {
		if theEvent.type == .KeyDown {
			switch theEvent.keyCode {
			case XUKeyCode.KeyUp.rawValue:
				self.arrowKeyUpPressed(theEvent)
				return
			case XUKeyCode.KeyDown.rawValue:
				self.arrowKeyDownPressed(theEvent)
				return
			case XUKeyCode.KeyRight.rawValue:
				self.arrowKeyRightPressed(theEvent)
				return
			case XUKeyCode.KeyLeft.rawValue:
				self.arrowKeyLeftPressed(theEvent)
				return
			default:
				break
			}
		}
		super.sendEvent(theEvent)
	}
	
}
