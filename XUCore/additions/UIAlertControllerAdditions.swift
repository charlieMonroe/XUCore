//
//  UIAlertControllerAdditions.swift
//  XUCore
//
//  Created by Charlie Monroe on 11/25/15.
//  Copyright © 2015 Charlie Monroe Software. All rights reserved.
//

import Foundation

public extension UIAlertController {
	
	/// See the init method.
	public class func alertControllerWithError(error: NSError?) -> UIAlertController {
		if error == nil {
			let alert = UIAlertController(title: XULocalizedString("Unknown error."), message: nil, preferredStyle: .Alert)
			alert.addAction(UIAlertAction(title: XULocalizedString("OK"), style: .Default, handler: nil))
			return alert
		}
		
		return UIAlertController(error: error!)
	}
	
	/// Creates a new alert controller with information from the error. By default,
	/// also adds an OK button. If you want all buttons of the alert to be custom,
	/// remove the existing action on the controller.
	public convenience init(error: NSError) {
		self.init(title: error.localizedFailureReason, message: error.localizedDescription, preferredStyle: .Alert)
		self.addAction(UIAlertAction(title: XULocalizedString("OK"), style: .Default, handler: nil))
	}
	
}


/// These properties are for allowing more shared code with OS X. This way,
/// you can declare NSAlert on OS X and UIAlertController on iOS and assign
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

