//
//  NSImageAdditions.swift
//  XUCore
//
//  Created by Charlie Monroe on 11/20/15.
//  Copyright © 2015 Charlie Monroe Software. All rights reserved.
//

import Foundation

#if os(iOS)
	import UIKit
	
	public typealias XUImage = UIImage
#else
	import Cocoa
	
	public typealias XUImage = NSImage
#endif

/// Public extension of NSImage or UIImage. You can use XUImage in your code,
/// to make it universal.
public extension XUImage {
	
	/// Draws the rect centered within rect with fraction 1.0.
	public func drawCenteredInRect(rect: CGRect) {
		self.drawCenteredInRect(rect, fraction: 1.0)
	}
	
	/// Draws the rect centered within rect. The image is scaled, if necessary.
	public func drawCenteredInRect(rect: CGRect, fraction: CGFloat) {
		let image = self
		let mySize = image.size
		var targetRect = rect
		if mySize.width / mySize.height > rect.width / rect.height {
			// Wider
			targetRect.size.width = rect.width
			targetRect.size.height = mySize.height * (rect.width / mySize.width)
			targetRect.origin.y = rect.minY + (rect.height - targetRect.height) / 2.0
		} else {
			// Taller
			targetRect.size.height = rect.height
			targetRect.size.width = mySize.width * (rect.height / mySize.height)
			targetRect.origin.x = rect.minX + (rect.width - targetRect.width) / 2.0
		}
		
		#if os(iOS)
			image.drawInRect(targetRect, blendMode: .Normal, alpha: fraction)
		#else
			image.drawInRect(targetRect, fromRect: CGRect(), operation: .CompositeSourceOver, fraction: fraction, respectFlipped: true, hints: nil)
		#endif
	}
	
	/// Proportionally scales the image to maximum size.
	public func proportinallyScaledSizeForMaxSize(size: CGSize) -> CGSize {
		let image = self
		let mySize = image.size
		if mySize.width < size.width && mySize.height < size.height {
			return mySize
		}
		
		var resultSize = CGSize()
		if mySize.width / mySize.height > size.width / size.height {
			// Wider
			resultSize.width = size.width
			resultSize.height = mySize.height * (size.width / mySize.width)
		}else{
			// Taller
			resultSize.height = size.height
			resultSize.width = mySize.width * (size.height / mySize.height)
		}
		return resultSize
	}
	
}
