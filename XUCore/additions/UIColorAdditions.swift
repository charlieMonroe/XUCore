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
		var hexString = originalHexString
		if hexString.characters.count == 6 || hexString.characters.count == 7 {
			hexString = hexString.deleting(prefix: "#")
		} else {
			return nil // Wrong fromat
		}
		
		let startIndex = hexString.startIndex
		let redByte = hexString.substring(with: startIndex ..< hexString.index(startIndex, offsetBy: 2)).hexValue
		let greenByte = hexString.substring(with: hexString.index(startIndex, offsetBy: 2) ..< hexString.index(startIndex, offsetBy: 4)).hexValue
		let blueByte = hexString.substring(with: hexString.index(startIndex, offsetBy: 4) ..< hexString.index(startIndex, offsetBy: 6)).hexValue
		
		self.init(red: CGFloat(redByte) / 255.0, green: CGFloat(greenByte) / 255.0, blue: CGFloat(blueByte) / 255.0, alpha: 1.0)
	}
	
}


