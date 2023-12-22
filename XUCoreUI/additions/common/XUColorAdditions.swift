//
//  UIColorAdditions.swift
//  XUCore
//
//  Created by Charlie Monroe on 11/21/15.
//  Copyright © 2015 Charlie Monroe Software. All rights reserved.
//

#if os(macOS)
	import AppKit
#else
	import UIKit
#endif

extension __XUBridgedColor {
	
	private func _offsettedRGBColor(by offset: CGFloat) -> __XUBridgedColor {
		var r: CGFloat = 0.0
		var g: CGFloat = 0.0
		var b: CGFloat = 0.0
		var alpha: CGFloat = 0.0
		
		#if os(macOS)
			let color: __XUBridgedColor
			if self.type == .catalog || self.colorSpace.cgColorSpace?.model != .rgb {
				guard let convertedColor = self.usingColorSpace(.deviceRGB) else {
					return self
				}
				
				color = convertedColor
			} else {
				color = self
			}
			color.getRed(&r, green: &g, blue: &b, alpha: &alpha) // Returns Void
		#else
			guard self.getRed(&r, green: &g, blue: &b, alpha: &alpha) else {
				return self
			}
		#endif
		
		r += offset
		g += offset
		b += offset
		
		if offset < 0.0 {
			r = max(0.0, r)
			g = max(0.0, g)
			b = max(0.0, b)
		} else {
			r = min(1.0, r)
			g = min(1.0, g)
			b = min(1.0, b)
		}
		
		return __XUBridgedColor(red: r, green: g, blue: b, alpha: alpha)
	}
	
	/// Returns a darker variant of the color by offset. Currently only works on
	/// RGB colors.
	public func darker(by offset: CGFloat) -> __XUBridgedColor {
		return self._offsettedRGBColor(by: offset * -1.0)
	}
		
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
	
	/// Returns lighter variant of the color by offset. Currently only works on
	/// RGB colors.
	public func lighterColor(by offset: CGFloat) -> __XUBridgedColor {
		return self._offsettedRGBColor(by: offset)
	}
	
	#if os(iOS)
	/// Creates an image with size that is a swatch of the color.
	public func swatchImage(with size: CGSize) -> UIImage {
		let renderer = UIGraphicsImageRenderer(size: size)
		return renderer.image { (ctx) in
			self.setFill()
			
			let bounds = CGRect(origin: .zero, size: size)
			UIBezierPath(rect: bounds).fill()
		}
	}
	#endif
	
}


