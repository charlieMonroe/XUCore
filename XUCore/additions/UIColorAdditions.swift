//
//  UIColorAdditions.swift
//  XUCore
//
//  Created by Charlie Monroe on 11/21/15.
//  Copyright © 2015 Charlie Monroe Software. All rights reserved.
//

import UIKit

public extension UIColor {
	
	/// Returns an image with size aSize that is filled with self. May return
	/// nil if UIGraphicsGetCurrentContext returns nil.
	public func colorSwatchOfSize(aSize: CGSize) -> UIImage? {
		let sideSize: CGFloat = 26.0
		let radius: CGFloat = min(6.0, sideSize / 2.0)
		
		let dstRect = CGRect(x: 0.0, y: 0.0, width: sideSize, height: sideSize)
		
		UIGraphicsBeginImageContext(dstRect.size)
		
		guard let ctx = UIGraphicsGetCurrentContext() else {
			return nil
		}
		
		self.set()
		
		CGContextAddRoundedRect(ctx, rect: dstRect, cornerRadius: radius)
		CGContextFillPath(ctx)
		
		UIColor.whiteColor().set()
		
		let maskedImage = UIGraphicsGetImageFromCurrentImageContext()
		UIGraphicsEndImageContext()
		return maskedImage
	}
	
}


