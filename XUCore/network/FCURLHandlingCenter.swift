//
//  FCURLHandlingCenter.swift
//  XUCore
//
//  Created by Charlie Monroe on 11/5/15.
//  Copyright © 2015 Charlie Monroe Software. All rights reserved.
//

import Cocoa

@objc public protocol FCURLHandler: AnyObject {
	
	/// Called when the application opens a URL via Apple Events.
	func handlerShouldProcessURL(URL: NSURL)
	
}


/// This object handles opening of URLs on OS X. On OS X, NSApplicationDelegate
/// doesn't get a -applicationShouldOpenURL: call, so we need to do this by adding
/// and AppleEvent handler.
public class FCURLHandlingCenter: NSObject {

	public static let defaultCenter = FCURLHandlingCenter()
	
	
	private var _handlers: [String : [FCURLHandler]] = [ : ]
	
	
	/// Adds a handler for scheme. Multiple handlers per scheme are allowed).
	/// A strong reference is made to the handler.
	public func addHandler(handler: FCURLHandler, forURLScheme scheme: String) {
		var handlers = _handlers[scheme] ?? [ ]
		handlers.append(handler)
		_handlers[scheme] = handlers
	}
	
	/// Private function that handler the AppleEvent calls.
	@objc private func handleURLEvent(event: NSAppleEventDescriptor, withReplyEvent replyEvent: NSAppleEventDescriptor) {
		guard let receivedURLString = event.paramDescriptorForKeyword(UInt32(keyDirectObject))?.stringValue else {
			FCLog("Cannot handle apple event - \(event)")
			return
		}
		
		guard let URL = NSURL(string: receivedURLString) else {
			FCLog("Invalid URLString - \(receivedURLString)")
			return
		}
		
		guard let handlers = _handlers[URL.scheme.lowercaseString] else {
			FCLog("No handler for URL scheme \(URL.scheme) - \(URL)")
			return
		}
		
		for handler in handlers {
			handler.handlerShouldProcessURL(URL)
		}
	}
	
	/// Removes the handler for all schemes.
	public func removeHandler(handler: FCURLHandler) {
		for scheme in _handlers.keys {
			self.removeHandler(handler, forURLScheme: scheme)
		}
	}
	
	/// Removes the handler for a particular scheme.
	public func removeHandler(handler: FCURLHandler, forURLScheme scheme: String) {
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
