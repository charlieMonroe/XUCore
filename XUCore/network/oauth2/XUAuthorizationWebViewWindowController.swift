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
	
	@IBOutlet private weak var _currentURLTextField: NSTextField!
	@IBOutlet private weak var _progressIndicator: NSProgressIndicator!
	@IBOutlet private weak var _webView: WebView!
	
	/// Completion handler
	private(set) var completionHandler: ((XUOAuth2Client.AuthorizationResult) -> Void)?
	
	/// URL this controller was initialized with.
	private(set) var url: URL!
	
	
	/// Closes the window and passes the result to self.completionHandler.
	func close(withResult result: XUOAuth2Client.AuthorizationResult) {
		NSApp.stopModal()
		
		self.window?.close()
		self.completionHandler?(result)
	}
	
	/// Only initialize the controller with this initializer.
	convenience init(url: URL) {
		self.init(windowNibName: "XUAuthorizationWebViewWindowController")
		
		self.url = url
	}
	
	@IBAction @objc private func cancel(_ sender: AnyObject?) {
		self.close(withResult: .error(.userCancelled))
	}
	
	/// Runs the window modally and will call completionHandler when it gets closed
	/// both by user and programatically.
	func runModal(withCompletionHandler completionHandler: ((XUOAuth2Client.AuthorizationResult) -> Void)?) {
		self.completionHandler = completionHandler
		
		self.window!.center()
		self.window!.makeKeyAndOrderFront(nil)
		
		NSApp.runModal(for: self.window!)
	}
	
	func webView(_ sender: WebView, didStartProvisionalLoadFor frame: WebFrame) {
		_progressIndicator.startAnimation(nil)
	}
	
	func webView(_ sender: WebView!, didCommitLoadFor frame: WebFrame!) {
		_currentURLTextField.stringValue = sender.mainFrameURL
	}
	
	func webView(_ sender: WebView, didFinishLoadFor frame: WebFrame) {
		_progressIndicator.stopAnimation(nil)
	}
	
	override func windowDidLoad() {
		super.windowDidLoad()
		
		_webView.mainFrameURL = self.url.absoluteString
		_currentURLTextField.stringValue = self.url.absoluteString
	}
	
}


