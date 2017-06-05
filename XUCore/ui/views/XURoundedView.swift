//
//  XURoundedView.swift
//  XUCore
//
//  Created by Charlie Monroe on 6/1/17.
//  Copyright © 2017 Charlie Monroe Software. All rights reserved.
//

import UIKit

/// This view automatically rounds its corners and makes sure it clips to bounds.
@IBDesignable
open class XURoundedView: UIView {
	
	@IBInspectable open var cornerRadius: CGFloat = 0.0 {
		didSet {
			self.layer.cornerRadius = self.cornerRadius
		}
	}
	
	open override func awakeFromNib() {
		super.awakeFromNib()
		
		self.layer.cornerRadius = self.cornerRadius
		self.layer.masksToBounds = true
	}
	
}
