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
@objc public enum XUKeyCode: UInt16 {
	case Return = 36
	case Enter = 76
	case Escape = 53
	case Backscape = 51
	case Delete = 117
	case Spacebar = 49
	case KeyLeft = 123
	case KeyRight = 124
	case KeyDown = 125
	case KeyUp = 126
}


public extension NSEvent {
	
	private class func _isKeyDown(key: UInt32) -> Bool {
		let currentKeyModifiers = GetCurrentKeyModifiers()
		let result = currentKeyModifiers & key
		return result != 0
	}
	
	/// Returns whether the Command key is currently held down.
	public class var commandKeyDown: Bool {
		return self._isKeyDown(UInt32(cmdKey))
	}
	
	/// Returns whether the Control key is currently held down.
	public class var controlKeyDown: Bool {
		return self._isKeyDown(UInt32(controlKey))
	}
	
	/// Returns whether the Option key is currently held down.
	public class var optionKeyDown: Bool {
		return self._isKeyDown(UInt32(optionKey))
	}
	
}
