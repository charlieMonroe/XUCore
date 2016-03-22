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
public class XUHorizontallyCenteredTextFieldCell: NSTextFieldCell {
	
	public override func drawWithFrame(cellFrame: CGRect, inView controlView: NSView) {
		let color = self.highlighted ? NSColor.whiteColor() : (self.textColor ?? NSColor.blackColor())
		let attributes = [ NSFontAttributeName: self.font!, NSForegroundColorAttributeName: color ]
		let textSize = self.stringValue.sizeWithAttributes(attributes)
		
		self.stringValue.drawAtPoint(CGPointMake(cellFrame.minX, cellFrame.minY + ((cellFrame.height - textSize.height) / 2.0)), withAttributes: attributes)
	}
	
}

@available(*, deprecated)
@objc(FCHorizontallyCenteredTextField) class FCHorizontallyCenteredTextField: XUHorizontallyCenteredTextFieldCell {
	
	override func awakeFromNib() {
		XULog("WARNING: Deprecated use of \(self.dynamicType) - use XUCore.\(self.superclass!) instead")
		
		super.awakeFromNib()
	}
	
}

