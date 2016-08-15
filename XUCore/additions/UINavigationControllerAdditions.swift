//
//  UINavigationControllerAdditions.swift
//  XUCore
//
//  Created by Charlie Monroe on 2/17/16.
//  Copyright © 2016 Charlie Monroe Software. All rights reserved.
//

import UIKit

public extension UINavigationController {
	
	/// This method allows you to observe when the navigation controller has 
	/// completed the animation. The completionHandler argument is required -
	/// if you don't need it, use the basic popViewControllerAnimated(_:) method.
	public func popViewController(animated: Bool, completionHandler: (Void) -> Void) {
		CATransaction.begin()
		CATransaction.setCompletionBlock(completionHandler)
		
		self.popViewControllerAnimated(animated)
		
		CATransaction.commit()
	}
	
	/// This method allows you to observe when the navigation controller has
	/// completed the animation. The completionHandler argument is required -
	/// if you don't need it, use the basic popViewControllerAnimated(_:) method.
	public func popToRootViewControllerAnimated(animated: Bool, completionHandler: (Void) -> Void) {
		CATransaction.begin()
		CATransaction.setCompletionBlock(completionHandler)
		
		self.popToRootViewControllerAnimated(animated)
		
		CATransaction.commit()
	}
	
}
