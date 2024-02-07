//
//  NSTextFieldAdditions.swift
//  XUCore
//
//  Created by Charlie Monroe on 11/10/15.
//  Copyright © 2015 Charlie Monroe Software. All rights reserved.
//

import AppKit

private let kBorderWidth: CGFloat = 10.0

public extension NSTextField {
	
	/// If downwards flag is NO, it only updates the frame's height, keeping the
	/// origin.
	func sizeToFit(keepingWidth resizeDownwards: Bool) -> CGRect {
		let textFrame = self.bounds.insetBy(dx: kBorderWidth, dy: kBorderWidth)
		let textHeight = self.stringValue.size(withAttributes: [.font: self.font!], maximumWidth: textFrame.width).height
		let deltaHeight = textFrame.height - textHeight
		
		var myFrame = self.frame
		myFrame.size.height -= deltaHeight
		if resizeDownwards {
			myFrame.origin.y += deltaHeight
		}
		
		self.frame = myFrame
		return myFrame
	}
	
}

