//
//  NSTextFieldAdditions.swift
//  XUCore
//
//  Created by Charlie Monroe on 11/10/15.
//  Copyright © 2015 Charlie Monroe Software. All rights reserved.
//

import Foundation

private let kBorderWidth: CGFloat = 10.0

public extension NSTextField {
	
	@available(*, deprecated, renamed: "sizeToFit(keepingWidth:)")
	public func sizeToFitKeepingWidth(_ resizeDownwards: Bool) -> CGRect {
		return self.sizeToFit(keepingWidth: resizeDownwards)
	}
	
	/// If downwards flag is NO, it only updates the frame's height, keeping the
	/// origin.
	public func sizeToFit(keepingWidth resizeDownwards: Bool) -> CGRect {
		let textFrame = self.bounds.insetBy(dx: kBorderWidth, dy: kBorderWidth)
		let textHeight = self.stringValue.size(withAttributes: [NSFontAttributeName: self.font!], maximumWidth: textFrame.width).height
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

