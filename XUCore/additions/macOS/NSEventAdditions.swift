//
//  NSEventAdditions.swift
//  XUCore
//
//  Created by Charlie Monroe on 11/9/15.
//  Copyright © 2015 Charlie Monroe Software. All rights reserved.
//

import Foundation
import Carbon

/// This enum holds key-code values of some less common keys
public enum XUKeyCode: UInt16 {
	case `return` = 36
	case enter = 76
	case escape = 53
	case backscape = 51
	case delete = 117
	case spacebar = 49
	case keyLeft = 123
	case keyRight = 124
	case keyDown = 125
	case keyUp = 126
}


public extension NSEvent {
	
	private class func _isKeyDown(_ key: UInt32) -> Bool {
		let currentKeyModifiers = GetCurrentKeyModifiers()
		let result = currentKeyModifiers & key
		return result != 0
	}
		
	/// Returns whether the Command key is currently held down.
	public class var isCommandKeyDown: Bool {
		return self._isKeyDown(UInt32(cmdKey))
	}
	
	/// Returns whether the Control key is currently held down.
	public class var isControlKeyDown: Bool {
		return self._isKeyDown(UInt32(controlKey))
	}
	
	/// Returns whether the Option key is currently held down.
	public class var isOptionKeyDown: Bool {
		return self._isKeyDown(UInt32(optionKey))
	}
	
	/// Returns whether the Shift key is currently held down.
	public class var isShiftKeyDown: Bool {
		return self._isKeyDown(UInt32(shiftKey))
	}
	
}
