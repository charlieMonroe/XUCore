//
//  UIViewAdditions.swift
//  XUCoreMobile
//
//  Created by Charlie Monroe on 7/13/18.
//  Copyright © 2018 Charlie Monroe Software. All rights reserved.
//

import UIKit

public extension UIView {
	
	/// Removes all subviews from the view.
	public func removeAllSubviews() {
		self.subviews.forEach({ $0.removeFromSuperview() })
	}
	
}
