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
	func mouseClickedAtPoint(_ point: CGPoint, atDisplay displayID: CGDirectDisplayID, withEventFlags flags: CGEventFlags)

	/// Called when the mouse moved to point.
	func mouseMovedToPoint(_ point: CGPoint, atDisplay displayID: CGDirectDisplayID, withEventFlags flags: CGEventFlags)

}

private func XUMouseMovementEventCallback(_ proxy: CGEventTapProxy, type: CGEventType, event: CGEvent, refcon: UnsafeMutableRawPointer) -> Unmanaged<CGEvent>? {
	let point = event.location
	var displayID: CGDirectDisplayID = 0
	var numOfDisplays: UInt32 = 0
	CGGetDisplaysWithPoint(point, 1, &displayID, &numOfDisplays)
	if numOfDisplays == 0 {
		XULog("No displays at { \(point.x), \(point.y) }")
		return Unmanaged.passRetained(event)
	}

	let flags = event.flags
	let mouseTracker = unsafeBitCast(refcon, to: XUMouseTracker.self)

	if type == .mouseMoved {
		mouseTracker._notifyObserversAboutMovementToPoint(point, atDisplay: displayID, withEventFlags: flags)
	} else if type == .leftMouseDown {
		mouseTracker._notifyObserversAboutClickAtPoint(point, atDisplay: displayID, withEventFlags: flags)
	}

	event.type = .mouseMoved

	return Unmanaged.passRetained(event)
}

/// This class allows mouse tracking.
open class XUMouseTracker: NSObject {

	fileprivate let _lock = NSLock()
	fileprivate var _observers: [XUMouseTrackingObserver] = []

	open static var sharedMouseTracker = XUMouseTracker()

	fileprivate func _notifyObserversAboutClickAtPoint(_ point: CGPoint, atDisplay displayID: CGDirectDisplayID, withEventFlags flags: CGEventFlags) {
		_lock.perform {
			for observer in self._observers {
				observer.mouseClickedAtPoint(point, atDisplay: displayID, withEventFlags: flags)
			}
		}
	}
	fileprivate func _notifyObserversAboutMovementToPoint(_ point: CGPoint, atDisplay displayID: CGDirectDisplayID, withEventFlags flags: CGEventFlags) {
		_lock.perform {
			for observer in self._observers {
				observer.mouseMovedToPoint(point, atDisplay: displayID, withEventFlags: flags)
			}
		}
	}
	@objc fileprivate func _trackingThread() {
		let eventMask = CGEventMask(1 << CGEventType.mouseMoved.rawValue) | CGEventMask(1 << CGEventType.leftMouseDown.rawValue) | CGEventMask(1 << CGEventType.leftMouseDragged.rawValue)
		let ptrToSelf = Unmanaged.passUnretained(self).toOpaque()
		guard let machPort = CGEvent.tapCreate(tap: .cgSessionEventTap, place: .headInsertEventTap, options: .listenOnly, eventsOfInterest: eventMask, callback: XUMouseMovementEventCallback as! CGEventTapCallBack, userInfo: ptrToSelf) else {
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

		CFRunLoopAddSource(runLoop, eventSrc, CFRunLoopMode.defaultMode)
		CFRunLoopRun()
	}

	open func addObserver(_ observer: XUMouseTrackingObserver) {
		_lock.perform {
			XULog("adding an observer \(observer)")
			self._observers.append(observer)
		}
	}

	public override init() {
		super.init()

		DispatchQueue.global(qos: .background).async { () -> Void in
			self._trackingThread()
		}
	}

	open func removeObserver(_ observer: XUMouseTrackingObserver) {
		_lock.perform {
			if let index = self._observers.index(where: { $0 === observer }) {
				self._observers.remove(at: index)
			}
		}
	}

}

