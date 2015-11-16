//
//  XUURLHandlingCenter.swift
//  XUCore
//
//  Created by Charlie Monroe on 11/5/15.
//  Copyright © 2015 Charlie Monroe Software. All rights reserved.
//

import Cocoa

@objc public protocol XUURLHandler: AnyObject {
	
	/// Called when the application opens a URL via Apple Events.
	func handlerShouldProcessURL(URL: NSURL)
	
}


/// This object handles opening of URLs on OS X. On OS X, NSApplicationDelegate
/// doesn't get a -applicationShouldOpenURL: call, so we need to do this by adding
/// and AppleEvent handler.
public class XUURLHandlingCenter: NSObject {

	public static let defaultCenter = XUURLHandlingCenter()
	
	
	private var _handlers: [String : [XUURLHandler]] = [ : ]
	
	
	/// Adds a handler for scheme. Multiple handlers per scheme are allowed).
	/// A strong reference is made to the handler.
	public func addHandler(handler: XUURLHandler, forURLScheme scheme: String) {
		var handlers = _handlers[scheme] ?? [ ]
		handlers.append(handler)
		_handlers[scheme] = handlers
	}
	
	/// Private function that handler the AppleEvent calls.
	@objc private func handleURLEvent(event: NSAppleEventDescriptor, withReplyEvent replyEvent: NSAppleEventDescriptor) {
		guard let receivedURLString = event.paramDescriptorForKeyword(UInt32(keyDirectObject))?.stringValue else {
			XULog("Cannot handle apple event - \(event)")
			return
		}
		
		guard let URL = NSURL(string: receivedURLString) else {
			XULog("Invalid URLString - \(receivedURLString)")
			return
		}
		
		guard let handlers = _handlers[URL.scheme.lowercaseString] else {
			XULog("No handler for URL scheme \(URL.scheme) - \(URL)")
			return
		}
		
		for handler in handlers {
			handler.handlerShouldProcessURL(URL)
		}
	}
	
	/// Removes the handler for all schemes.
	public func removeHandler(handler: XUURLHandler) {
		for scheme in _handlers.keys {
			self.removeHandler(handler, forURLScheme: scheme)
		}
	}
	
	/// Removes the handler for a particular scheme.
	public func removeHandler(handler: XUURLHandler, forURLScheme scheme: String) {
		guard var schemes = _handlers[scheme] else {
			return
		}
		
		guard let index = schemes.indexOf({ $0 === handler }) else {
			return // Not registered for this scheme
		}
		
		schemes.removeAtIndex(index)
		_handlers[scheme] = schemes
	}
	
	
	/// Making init private
	private override init() {
		super.init()
		
		NSAppleEventManager.sharedAppleEventManager().setEventHandler(self, andSelector: "handleURLEvent:withReplyEvent:", forEventClass: UInt32(kInternetEventClass), andEventID: UInt32(kAEGetURL))
	}
	
}
