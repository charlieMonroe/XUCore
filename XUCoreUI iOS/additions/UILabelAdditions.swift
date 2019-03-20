//
//  UILabelAdditions.swift
//  XUCore
//
//  Created by Charlie Monroe on 2/22/17.
//  Copyright © 2017 Charlie Monroe Software. All rights reserved.
//

import UIKit

extension UILabel {
	
	/// Convenience initializer that takes in text, font and color.
	public convenience init(text: String, font: UIFont? = nil, color: UIColor = UIColor.darkText) {
		self.init()
		
		self.text = text
		self.font = font
		self.textColor = color
	}
	
}
