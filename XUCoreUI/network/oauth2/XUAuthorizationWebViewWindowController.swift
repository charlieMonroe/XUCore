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
internal final class XUAuthorizationWebViewWindowController: NSWindowController, WKNavigationDelegate {
	
	@IBOutlet private weak var _currentURLTextField: NSTextField!
	@IBOutlet private weak var _progressIndicator: NSProgressIndicator!
	@IBOutlet private weak var _webView: WKWebView!
	
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
	
	@IBAction private func cancel(_ sender: AnyObject?) {
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
	
	func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
		_progressIndicator.startAnimation(nil)
	
		_currentURLTextField.stringValue = webView.url?.absoluteString ?? ""
	}
	
	func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
		_progressIndicator.stopAnimation(nil)
	}
	
	override func windowDidLoad() {
		super.windowDidLoad()
		
		_webView.load(URLRequest(url: self.url))
		_currentURLTextField.stringValue = self.url.absoluteString
	}
	
}


