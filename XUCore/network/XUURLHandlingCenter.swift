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
	func handlerShouldProcessURL(_ URL: URL)
	
}


/// This object handles opening of URLs on OS X. On OS X, NSApplicationDelegate
/// doesn't get a -applicationShouldOpenURL: call, so we need to do this by adding
/// and AppleEvent handler.
public final class XUURLHandlingCenter: NSObject {

	public static let defaultCenter = XUURLHandlingCenter()
	
	
	fileprivate var _handlers: [String : [XUURLHandler]] = [ : ]
	
	
	/// Adds a handler for scheme. Multiple handlers per scheme are allowed).
	/// A strong reference is made to the handler.
	public func add(handler: XUURLHandler, forURLScheme scheme: String) {
		var handlers = _handlers[scheme] ?? [ ]
		handlers.append(handler)
		_handlers[scheme] = handlers
	}
	
	/// Private function that handler the AppleEvent calls.
	@objc fileprivate func handleURLEvent(_ event: NSAppleEventDescriptor, withReplyEvent replyEvent: NSAppleEventDescriptor) {
		guard let receivedURLString = event.paramDescriptor(forKeyword: UInt32(keyDirectObject))?.stringValue else {
			XULog("Cannot handle apple event - \(event)")
			return
		}
		
		guard let url = URL(string: receivedURLString) else {
			XULog("Invalid URLString - \(receivedURLString)")
			return
		}
		
		guard let handlers = _handlers[(url.scheme?.lowercased())!] else {
			XULog("No handler for URL scheme \(url.scheme!) - \(url)")
			return
		}
		
		for handler in handlers {
			handler.handlerShouldProcessURL(url)
		}
	}
	
	/// Removes the handler for all schemes.
	public func remove(handler: XUURLHandler) {
		for scheme in _handlers.keys {
			self.remove(handler: handler, forURLScheme: scheme)
		}
	}
	
	/// Removes the handler for a particular scheme.
	public func remove(handler: XUURLHandler, forURLScheme scheme: String) {
		guard var schemes = _handlers[scheme] else {
			return
		}
		
		guard let index = schemes.index(where: { $0 === handler }) else {
			return // Not registered for this scheme
		}
		
		schemes.remove(at: index)
		_handlers[scheme] = schemes
	}
	
	
	/// Making init private
	fileprivate override init() {
		super.init()
		
		NSAppleEventManager.shared().setEventHandler(self, andSelector: #selector(XUURLHandlingCenter.handleURLEvent(_:withReplyEvent:)), forEventClass: UInt32(kInternetEventClass), andEventID: UInt32(kAEGetURL))
	}
	
}
