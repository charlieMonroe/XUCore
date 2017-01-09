//
//  CGGraphicsAdditions.swift
//  XUCore
//
//  Created by Charlie Monroe on 3/1/16.
//  Copyright © 2016 Charlie Monroe Software. All rights reserved.
//

import Foundation
#if os(iOS)
	import UIKit
#else
	import Cocoa
#endif

public extension CGRect {
	
	/// Returns bottom half. Bottom by coordinates, doesn't take into account flipped
	/// graphics context.
	public var bottomHalf: CGRect {
		return CGRect(x: self.minX, y: self.minY, width: self.width, height: self.height)
	}
	
	public var center: CGPoint {
		return CGPoint(x: self.midX, y: self.midY)
	}

	/// Centers the rect so that self.center is the same as the returned value's.
	public func centerRect(in rect: CGRect) -> CGRect {
		let origin = CGPoint(x: self.minX + (self.width - rect.width) / 2.0, y: self.minY + (self.height - rect.height) / 2.0)
		return CGRect(origin: origin, size: rect.size)
	}
	
	/// Returns max of self.width and self.height.
	public var maxSize: CGFloat {
		return max(self.width, self.height)
	}
	
	/// Returns min of self.width and self.height.
	public var minSize: CGFloat {
		return min(self.width, self.height)
	}
	
	/// Returns top half. Top by coordinates, doesn't take into account flipped
	/// graphics context.
	public var topHalf: CGRect {
		return CGRect(x: self.minX, y: self.midY, width: self.width, height: self.height)
	}

}


public extension CGSize {
	
	/// Returns a copy of self that contains integral width and height.
	public var integral: CGSize {
		return CGSize(width: Int(self.width), height: Int(self.height))
	}
	
	/// Returns true if both width and height is zero.
	public var isEmpty: Bool {
		return self.height.isZero && self.width.isZero
	}
	
}
