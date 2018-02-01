//
//  UIViewController+Additions.swift
//  XUCoreMobile
//
//  Created by Charlie Monroe on 1/20/18.
//  Copyright © 2018 Charlie Monroe Software. All rights reserved.
//

import UIKit

extension UIViewController {
	
	/// A convenience method that will make UIAlertController from the error
	/// and present it via self.
	public func presentError(_ error: Error) {
		self.present(UIAlertController(error: error, completionHandler: nil), animated: true, completion: nil)
	}
	
}
