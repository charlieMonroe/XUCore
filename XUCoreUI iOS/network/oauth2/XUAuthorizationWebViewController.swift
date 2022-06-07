//
//  XUAuthorizationWebViewController.swift
//  XUCore
//
//  Created by Charlie Monroe on 6/24/16.
//  Copyright © 2016 Charlie Monroe Software. All rights reserved.
//

import UIKit
import WebKit
import XUCore

internal final class XUAuthorizationWebViewController: UIViewController {
	
	private let _webView: WKWebView = WKWebView()
	
	/// Completion handler
	private(set) var completionHandler: ((XUOAuth2Client.AuthorizationResult) -> Void)?

	/// URL this controller was initialized with.
	let url: URL

	
	
	/// Closes the window and passes the result to self.completionHandler.
	func close(withResult result: XUOAuth2Client.AuthorizationResult) {
		self.dismiss(animated: true) {
			self.completionHandler?(result)
		}
	}
	
	init(url: URL) {
		self.url = url
		
		super.init(nibName: nil, bundle: nil)
		
		self.view = _webView
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	@IBAction @objc private func cancel(_ sender: AnyObject?) {
		self.close(withResult: .error(.userCancelled))
	}
	
	/// Runs the window modally and will call completionHandler when it gets closed
	/// both by user and programatically.
	func present(fromController controller: UIViewController, withCompletionHandler completionHandler: ((XUOAuth2Client.AuthorizationResult) -> Void)?) {
		self.completionHandler = completionHandler
		
		let navController = UINavigationController(rootViewController: self)
		controller.present(navController, animated: true, completion: nil)
	}


	override func viewDidLoad() {
		super.viewDidLoad()
		
		self.title = Localized("Authentication", in: .core)
		self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancel(_:)))
		
		_webView.load(URLRequest(url: self.url))
	}
	
	
}
