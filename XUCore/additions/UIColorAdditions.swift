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
	
	/// Initializes self from a hexString color.
	public convenience init?(hexString originalHexString: String) {
		var hexString = originalHexString
		if hexString.characters.count == 6 || hexString.characters.count == 7 {
			hexString = hexString.stringByDeletingPrefix("#")
		} else {
			return nil // Wrong fromat
		}
		
		let startIndex = hexString.startIndex
		let redByte = hexString.substringWithRange(startIndex ..< startIndex.advancedBy(2)).hexValue
		let greenByte = hexString.substringWithRange(startIndex.advancedBy(2) ..< startIndex.advancedBy(4)).hexValue
		let blueByte = hexString.substringWithRange(startIndex.advancedBy(4) ..< startIndex.advancedBy(6)).hexValue
		
		self.init(red: CGFloat(redByte) / 255.0, green: CGFloat(greenByte) / 255.0, blue: CGFloat(blueByte) / 255.0, alpha: 1.0)
	}
	
}


