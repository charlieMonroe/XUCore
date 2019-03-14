//
//  UIAlertControllerAdditions.swift
//  XUCore
//
//  Created by Charlie Monroe on 11/25/15.
//  Copyright © 2015 Charlie Monroe Software. All rights reserved.
//

import Foundation
import UIKit

extension UIAlertController {
	
	/// Adds a cancel action.
	public func addCancelAction(completionHandler: ((UIAlertAction) -> Void)? = nil) {
		self.addAction(UIAlertAction(cancelWithCompletionHandler: completionHandler))
	}
	
	/// Adds an action with localized "OK" title.
	public func addOKAction(completionHandler: ((UIAlertAction) -> Void)? = nil) {
		self.addAction(UIAlertAction(title: XULocalizedString("OK", inBundle: XUCoreFramework.bundle), style: .default, handler: completionHandler))
	}
	
	/// Creates a new alert controller with information from the error. By default,
	/// also adds an OK button. If you want all buttons of the alert to be custom,
	/// remove the existing action on the controller.
	@objc public convenience init(error: Error, completionHandler: (() -> Void)? = nil) {
		self.init(title: (error as NSError).localizedFailureReason, message: (error as NSError).localizedDescription, preferredStyle: .alert)
		self.addAction(UIAlertAction(title: XULocalizedString("OK", inBundle: XUCoreFramework.bundle), style: .default, handler: { (_) in
			if let handler = completionHandler {
				handler()
			}
		}))
	}
	
	/// Initializes self with no title or message but with particular style. This
	/// is to be used like this:
	///
	/// let alert = UIAlertController(style: .alert)
	/// alert.message = "123"
	/// alert.title = "456"
	public convenience init(style: UIAlertController.Style) {
		self.init(title: nil, message: nil, preferredStyle: style)
	}
	
}

public extension UIAlertAction {
	
	/// A conveniece for a Cancel action.
	public convenience init(cancelWithCompletionHandler completionHandler: ((UIAlertAction) -> Void)?) {
		self.init(title: XULocalizedString("Cancel", inBundle: XUCoreFramework.bundle), style: .cancel, handler: completionHandler)
	}
	
}


/// These properties are for allowing more shared code with OS X. This way,
/// you can declare NSAlert on macOS and UIAlertController on iOS and assign
/// these variables to both.
public extension UIAlertController {
	
	public var informativeText: String? {
		get {
			return self.message
		}
		set {
			self.message = newValue
		}
	}
	
	public var messageText: String? {
		get {
			return self.title
		}
		set {
			self.title = newValue
		}
	}
	
}

