//
//  XUMouseTracker.swift
//  XUCore
//
//  Created by Charlie Monroe on 11/11/15.
//  Copyright © 2015 Charlie Monroe Software. All rights reserved.
//

import CoreGraphics
import Foundation
import XUCore

public protocol XUMouseTrackingObserver: AnyObject {

	/// Called when the mouse clicked at point.
	func mouseClicked(at point: CGPoint, atDisplay displayID: CGDirectDisplayID, withEventFlags flags: CGEventFlags)

	/// Called when the mouse moved to point.
	func mouseMoved(to point: CGPoint, atDisplay displayID: CGDirectDisplayID, withEventFlags flags: CGEventFlags)

}


/// This class allows mouse tracking.
public final class XUMouseTracker {

	private let _lock = NSLock(name: "XUCore.XUMouseTracker")
	private var _observers: [XUMouseTrackingObserver] = []

	public static let shared = XUMouseTracker()

	private func _notifyObserversAboutClickAtPoint(_ point: CGPoint, atDisplay displayID: CGDirectDisplayID, withEventFlags flags: CGEventFlags) {
		_lock.perform {
			for observer in self._observers {
				observer.mouseClicked(at: point, atDisplay: displayID, withEventFlags: flags)
			}
		}
	}
	private func _notifyObserversAboutMovementToPoint(_ point: CGPoint, atDisplay displayID: CGDirectDisplayID, withEventFlags flags: CGEventFlags) {
		DispatchQueue.main.syncOrNow {
			self._lock.perform {
				for observer in self._observers {
					observer.mouseMoved(to: point, atDisplay: displayID, withEventFlags: flags)
				}
			}
		}
	}
	@objc private func _trackingThread() {
		let eventMask = CGEventMask(1 << CGEventType.mouseMoved.rawValue) | CGEventMask(1 << CGEventType.leftMouseDown.rawValue) | CGEventMask(1 << CGEventType.leftMouseDragged.rawValue)
		let ptrToSelf = Unmanaged.passUnretained(self).toOpaque()
		guard let machPort = CGEvent.tapCreate(tap: .cgSessionEventTap, place: .headInsertEventTap, options: .listenOnly, eventsOfInterest: eventMask, callback: { (proxy, type, event, refcon) in
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
		}, userInfo: ptrToSelf) else {
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

	public func add(observer: XUMouseTrackingObserver) {
		_lock.perform {
			XULog("adding an observer \(observer)")
			self._observers.append(observer)
		}
	}

	public init() {
		DispatchQueue.global(qos: .background).async { () -> Void in
			self._trackingThread()
		}
	}

	public func remove(observer: XUMouseTrackingObserver) {
		_lock.perform {
			if let index = self._observers.firstIndex(where: { $0 === observer }) {
				self._observers.remove(at: index)
			}
		}
	}

}

