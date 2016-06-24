//
//  XUAuthorizationWebViewWindowController.swift
//  Eon
//
//  Created by Charlie Monroe on 1/22/16.
//  Copyright © 2016 Charlie Monroe Software. All rights reserved.
//

import Foundation
import WebKit

/// This is used for OAuth 2.x authentication. It is automatically closed when
/// the client receives a redirection.
internal final class XUAuthorizationWebViewWindowController: NSWindowController, WebFrameLoadDelegate {
	
	@IBOutlet private var _currentURLTextField: NSTextField!
	@IBOutlet private var _progressIndicator: NSProgressIndicator!
	@IBOutlet private var _webView: WebView!
	
	/// Completion handler
	private(set) var completionHandler: ((XUOAuth2Client.AuthorizationResult) -> Void)?
	
	/// URL this controller was initialized with.
	private(set) var URL: NSURL!
	
	
	/// Closes the window and passes the result to self.completionHandler.
	func close(withResult result: XUOAuth2Client.AuthorizationResult) {
		NSApp.stopModal()
		
		self.window?.close()
		self.completionHandler?(result)
	}
	
	/// Only initialize the controller with this initializer.
	convenience init(URL: NSURL) {
		self.init(windowNibName: "XUAuthorizationWebViewWindowController")
		
		self.URL = URL
	}
	
	@IBAction @objc private func cancel(sender: AnyObject?) {
		self.close(withResult: .Error(.UserCancelled))
	}
	
	/// Runs the window modally and will call completionHandler when it gets closed
	/// both by user and programatically.
	func runModal(withCompletionHandler completionHandler: ((XUOAuth2Client.AuthorizationResult) -> Void)?) {
		self.completionHandler = completionHandler
		
		self.window!.center()
		self.window!.makeKeyAndOrderFront(nil)
		
		NSApp.runModalForWindow(self.window!)
	}
	
	func webView(sender: WebView, didStartProvisionalLoadForFrame frame: WebFrame) {
		_progressIndicator.startAnimation(nil)
	}
	
	func webView(sender: WebView!, didCommitLoadForFrame frame: WebFrame!) {
		_currentURLTextField.stringValue = sender.mainFrameURL
	}
	
	func webView(sender: WebView, didFinishLoadForFrame frame: WebFrame) {
		_progressIndicator.stopAnimation(nil)
	}
	
	override func windowDidLoad() {
		super.windowDidLoad()
		
		_webView.mainFrameURL = self.URL.absoluteString
		_currentURLTextField.stringValue = self.URL.absoluteString
	}
	
}


