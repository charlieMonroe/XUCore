//
//  UIColorAdditions.swift
//  XUCore
//
//  Created by Charlie Monroe on 11/21/15.
//  Copyright © 2015 Charlie Monroe Software. All rights reserved.
//

import UIKit

public extension UIColor {
		
	/// Initializes self from a hexString color.
	public convenience init?(hexString originalHexString: String) {
		let hexString = originalHexString.deleting(prefix: "#")
		guard hexString.count == 6 || hexString.count == 8 else {
			return nil // Wrong fromat
		}
		
		let startIndex = hexString.startIndex
		let redByte = String(hexString[startIndex ..< hexString.index(startIndex, offsetBy: 2)]).hexValue
		let greenByte = String(hexString[hexString.index(startIndex, offsetBy: 2) ..< hexString.index(startIndex, offsetBy: 4)]).hexValue
		let blueByte = String(hexString[hexString.index(startIndex, offsetBy: 4) ..< hexString.index(startIndex, offsetBy: 6)]).hexValue
		
		let alpha: CGFloat
		if hexString.count == 8 {
			let alphaByte = String(hexString[hexString.index(startIndex, offsetBy: 6) ..< hexString.index(startIndex, offsetBy: 8)]).hexValue
			alpha = CGFloat(alphaByte) / 255.0
		} else {
			alpha = 1.0
		}
		
		self.init(red: CGFloat(redByte) / 255.0, green: CGFloat(greenByte) / 255.0, blue: CGFloat(blueByte) / 255.0, alpha: alpha)
	}
	
	/// Creates an image with size that is a swatch of the color.
	public func swatchImage(with size: CGSize) -> UIImage {
		let renderer = UIGraphicsImageRenderer(size: size)
		return renderer.image { (ctx) in
			self.setFill()
			
			let bounds = CGRect(origin: .zero, size: size)
			UIBezierPath(rect: bounds).fill()
		}
	}
	
}


