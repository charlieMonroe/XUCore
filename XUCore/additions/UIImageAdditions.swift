//
//  UIImageAdditions.swift
//  XUCore
//
//  Created by Charlie Monroe on 11/30/15.
//  Copyright © 2015 Charlie Monroe Software. All rights reserved.
//

import UIKit

public extension UIImage {
	
	/// Applies color tint to the image.
	public func imageByApplyingTintColor(color: UIColor) -> UIImage {
		var imageRect = CGRectZero
		imageRect.size = self.size
		
		UIGraphicsBeginImageContextWithOptions(imageRect.size, false, self.scale)
		
		let context = UIGraphicsGetCurrentContext()
		
		CGContextScaleCTM(context, 1.0, -1.0)
		CGContextTranslateCTM(context, 0.0, -(imageRect.height))
		CGContextClipToMask(context, imageRect, self.CGImage)
		CGContextSetFillColorWithColor(context, color.CGColor)
		CGContextFillRect(context, imageRect)
		
		let newImage = UIGraphicsGetImageFromCurrentImageContext()
		UIGraphicsEndImageContext()
		return newImage
	}
	
	/// Returns a proportionally resized image to targetSize.
	public func imageResizedToSize(targetSize: CGSize) -> UIImage {
		let size = self.size
		if size.width <= targetSize.width && size.height <= targetSize.height {
			return self
		}
		
		var newSize = CGSizeZero
		if size.width > size.height {
			var width = targetSize.width
			var height = size.height * (targetSize.width / size.width)
			if height > targetSize.height {
				height = targetSize.height
				width = size.width * (targetSize.height / size.height)
			}
			newSize.width = width
			newSize.height = height
		}else{
			var width = size.width * (targetSize.height / size.height)
			var height = targetSize.height
			if width > targetSize.width {
				width = targetSize.width
				height = size.height * (targetSize.width / size.width)
			}
			newSize.width = width
			newSize.height = height
		}
		
		UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
		self.drawInRect(CGRect(x: 0.0, y: 0.0, width: newSize.width, height: newSize.height))
		let newImage = UIGraphicsGetImageFromCurrentImageContext()
		UIGraphicsEndImageContext()
		return newImage
	}
	
	/// Returns PNG representation of the image.
	public var PNGRepresentation: NSData? {
		return UIImagePNGRepresentation(self)
	}
	
}


