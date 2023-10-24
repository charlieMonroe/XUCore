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
				NSAttributedString.Key.foregroundColor: UIColor(white: 0.3, alpha: 1.0),
				NSAttributedString.Key.font: self.font ?? UIFont.systemFont(ofSize: 13.0)
			])
		}
	}
	
	public override func draw(_ rect: CGRect) {
		let bounds = self.bounds
		UIColor.white.set()
		UIBezierPath(roundedRect: bounds, cornerRadius: bounds.height / 2.0).fill()
		
		super.draw(rect)
	}
	
	public override var bounds: CGRect {
		didSet {
			#if os(iOS)
				self.setNeedsDisplay()
			#else
				self.needsDisplay = true
			#endif
		}
	}
	
}
