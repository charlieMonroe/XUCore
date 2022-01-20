//
//  HelpBookViewerWindowController.swift
//  XUCore
//
//  Created by Charlie Monroe on 1/13/22.
//  Copyright © 2022 Charlie Monroe Software. All rights reserved.
//

import AppKit
import Foundation
import WebKit

// TODO - migrate to XUCoreUI instead.
internal final class HelpBookViewerWindowController: NSWindowController, NSWindowDelegate {
	
	private static var _sharedController: HelpBookViewerWindowController?
	
	static var shared: HelpBookViewerWindowController {
		if let shared = _sharedController {
			return shared
		}
		
		let controller = HelpBookViewerWindowController(windowNibName: "HelpBookViewerWindow")
		_sharedController = controller
		return controller
	}
	
	
	@objc dynamic var webView: NSView? {
		return self.window?.contentView?.subviews.first
	}
	
	func openHTML(at url: URL) {
		DispatchQueue.main.asyncAfter(deadline: .seconds(0.05), execute: {
			(self.window!.contentView?.subviews[0] as! WKWebView).load(URLRequest(url: url))
			self.showWindow(nil)
		})
	}
	
	override func windowDidLoad() {
		super.windowDidLoad()
		
		self.window!.delegate = self
	}
	
//	override var windowNibPath: String? {
//		return Bundle.core.path(forResource: "", ofType: "nib")
//	}
	
	func windowWillClose(_ notification: Notification) {
		if Self._sharedController == self {
			Self._sharedController = nil
		}
	}
	
}
