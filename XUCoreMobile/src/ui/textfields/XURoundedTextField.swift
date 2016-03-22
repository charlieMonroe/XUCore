//
//  XURoundedTextField.swift
//  XUCore
//
//  Created by Charlie Monroe on 12/3/15.
//  Copyright © 2015 Charlie Monroe Software. All rights reserved.
//

import UIKit


/// A text field whose layer is automatically set a corner radius of half the 
/// frame height.
@IBDesignable public class XURoundedTextField: UITextField {
	
	public override func awakeFromNib() {
		super.awakeFromNib()
		
		if let placeholder = self.placeholder {
			self.attributedPlaceholder = NSAttributedString(string: placeholder, attributes: [
				NSForegroundColorAttributeName: UIColor(white: 0.3, alpha: 1.0),
				NSFontAttributeName: self.font ?? UIFont.systemFontOfSize(13.0)
			])
		}
	}
	
	public override func drawRect(rect: CGRect) {
		let bounds = self.bounds
		UIColor.whiteColor().set()
		UIBezierPath(roundedRect: bounds, cornerRadius: bounds.height / 2.0).fill()
		
		super.drawRect(rect)
	}
	
	public override var bounds: CGRect {
		didSet {
			self.setNeedsDisplay()
		}
	}
	
}
