//
//  XUMouseTracker.swift
//  XUCore
//
//  Created by Charlie Monroe on 11/11/15.
//  Copyright © 2015 Charlie Monroe Software. All rights reserved.
//

import Foundation

@objc public protocol XUMouseTrackingObserver: NSObjectProtocol {

	/// Called when the mouse clicked at point.
	func mouseClickedAtPoint(point: CGPoint, atDisplay displayID: CGDirectDisplayID, withEventFlags flags: CGEventFlags)

	/// Called when the mouse moved to point.
	func mouseMovedToPoint(point: CGPoint, atDisplay displayID: CGDirectDisplayID, withEventFlags flags: CGEventFlags)

}

private func XUMouseMovementEventCallback(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent, refcon: UnsafeMutablePointer<Void>) -> Unmanaged<CGEvent>? {
	let point = CGEventGetLocation(event)
	var displayID: CGDirectDisplayID = 0
	var numOfDisplays: UInt32 = 0
	CGGetDisplaysWithPoint(point, 1, &displayID, &numOfDisplays)
	if numOfDisplays == 0 {
		XULog("No displays at { \(point.x), \(point.y) }")
		return Unmanaged.passRetained(event)
	}

	let flags = CGEventGetFlags(event)
	let mouseTracker = unsafeBitCast(refcon, XUMouseTracker.self)

	if type == .MouseMoved {
		mouseTracker._notifyObserversAboutMovementToPoint(point, atDisplay: displayID, withEventFlags: flags)
	} else if type == .LeftMouseDown {
		mouseTracker._notifyObserversAboutClickAtPoint(point, atDisplay: displayID, withEventFlags: flags)
	}

	CGEventSetType(event, .MouseMoved)

	return Unmanaged.passRetained(event)
}

/// This class allows mouse tracking.
public class XUMouseTracker: NSObject {

	private let _lock = NSLock()
	private var _observers: [XUMouseTrackingObserver] = []

	public static var sharedMouseTracker = XUMouseTracker()

	private func _notifyObserversAboutClickAtPoint(point: CGPoint, atDisplay displayID: CGDirectDisplayID, withEventFlags flags: CGEventFlags) {
		_lock.performLockedBlock {
			for observer in self._observers {
				observer.mouseClickedAtPoint(point, atDisplay: displayID, withEventFlags: flags)
			}
		}
	}
	private func _notifyObserversAboutMovementToPoint(point: CGPoint, atDisplay displayID: CGDirectDisplayID, withEventFlags flags: CGEventFlags) {
		_lock.performLockedBlock {
			for observer in self._observers {
				observer.mouseMovedToPoint(point, atDisplay: displayID, withEventFlags: flags)
			}
		}
	}
	@objc private func _trackingThread() {
		let eventMask = CGEventMask(1 << CGEventType.MouseMoved.rawValue) | CGEventMask(1 << CGEventType.LeftMouseDown.rawValue) | CGEventMask(1 << CGEventType.LeftMouseDragged.rawValue)
		guard let machPort = CGEventTapCreate(.CGSessionEventTap, .HeadInsertEventTap, .ListenOnly, eventMask, XUMouseMovementEventCallback, UnsafeMutablePointer(unsafeAddressOf(self))) else {
			XULog("NULL event port")
			return
		}

		guard let eventSrc = CFMachPortCreateRunLoopSource(nil, machPort, 0) else {
			XULog("No event run loop src?")
			return
		}

		guard let runLoop = CFRunLoopGetCurrent() else {
			XULog("No run loop?")
			return
		}

		CFRunLoopAddSource(runLoop, eventSrc, kCFRunLoopDefaultMode)
		CFRunLoopRun()
	}

	public func addObserver(observer: XUMouseTrackingObserver) {
		_lock.performLockedBlock {
			XULog("adding an observer \(observer)")
			self._observers.append(observer)
		}
	}

	public override init() {
		super.init()

		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)) { () -> Void in
			self._trackingThread()
		}
	}

	public func removeObserver(observer: XUMouseTrackingObserver) {
		_lock.performLockedBlock {
			if let index = self._observers.indexOf({ $0 === observer }) {
				self._observers.removeAtIndex(index)
			}
		}
	}

}

