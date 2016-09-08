//
//  XUHorizontallyCenteredTextField.swift
//  XUCore
//
//  Created by Charlie Monroe on 11/24/15.
//  Copyright © 2015 Charlie Monroe Software. All rights reserved.
//

import Foundation

/// Unlike regular text field cell, this cell centers the content horizontally
/// as well.
open class XUHorizontallyCenteredTextFieldCell: NSTextFieldCell {
	
	open override func draw(withFrame cellFrame: CGRect, in controlView: NSView) {
		let color = self.isHighlighted ? NSColor.white : (self.textColor ?? NSColor.black)
		let attributes = [ NSFontAttributeName: self.font!, NSForegroundColorAttributeName: color ] as [String : Any]
		let textSize = self.stringValue.size(withAttributes: attributes)
		
		self.stringValue.draw(at: CGPoint(x: cellFrame.minX, y: cellFrame.minY + ((cellFrame.height - textSize.height) / 2.0)), withAttributes: attributes)
	}
	
}
