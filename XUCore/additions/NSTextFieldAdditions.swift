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
	
	/// If downwards flag is NO, it only updates the frame's height, keeping the
	/// origin.
	public func sizeToFitKeepingWidth(resizeDownwards: Bool) -> CGRect {
		let textFrame = CGRectInset(self.bounds, kBorderWidth, kBorderWidth)
		let textHeight = self.stringValue.heightForWidth(CGRectGetWidth(textFrame), font: self.font)
		let deltaHeight = CGRectGetHeight(textFrame) - textHeight
		
		var myFrame = self.frame
		myFrame.size.height -= deltaHeight
		if resizeDownwards {
			myFrame.origin.y += deltaHeight
		}
		
		self.frame = myFrame
		return myFrame
	}
	
}

