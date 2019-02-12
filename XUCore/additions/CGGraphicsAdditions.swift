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
	var bottomHalf: CGRect {
		return CGRect(x: self.minX, y: self.minY, width: self.width, height: self.height / 2.0)
	}
	
	var center: CGPoint {
		return CGPoint(x: self.midX, y: self.midY)
	}

	/// Centers the rect so that self.center is the same as the returned value's.
	func centeringRectInSelf(_ rect: CGRect) -> CGRect {
		let origin = CGPoint(x: self.minX + (self.width - rect.width) / 2.0, y: self.minY + (self.height - rect.height) / 2.0)
		return CGRect(origin: origin, size: rect.size)
	}
	
	/// Returns max of self.width and self.height.
	var maxSize: CGFloat {
		return max(self.width, self.height)
	}
	
	/// Returns min of self.width and self.height.
	var minSize: CGFloat {
		return min(self.width, self.height)
	}
	
	/// Returns top half. Top by coordinates, doesn't take into account flipped
	/// graphics context.
	var topHalf: CGRect {
		return CGRect(x: self.minX, y: self.midY, width: self.width, height: self.height / 2.0)
	}

}

/// Returns lhs multiplied by rhs.
public func *(_ lhs: CGSize, _ rhs: CGFloat) -> CGSize {
	return CGSize(width: lhs.width * rhs, height: lhs.height * rhs)
}

/// Returns lhs multiplied by rhs.
public func *(_ lhs: CGSize, _ rhs: Double) -> CGSize {
	return CGSize(width: lhs.width * CGFloat(rhs), height: lhs.height * CGFloat(rhs))
}

/// Multiplies lhs by rhs.
public func *=(_ lhs: inout CGSize, _ rhs: CGFloat) {
	lhs.width *= rhs
	lhs.height *= rhs
}

/// Multiplies lhs by rhs.
public func *=(_ lhs: inout CGSize, _ rhs: Double) {
	lhs.width *= CGFloat(rhs)
	lhs.height *= CGFloat(rhs)
}


/// Returns lhs divided by rhs.
public func /(_ lhs: CGSize, _ rhs: CGFloat) -> CGSize {
	return CGSize(width: lhs.width / rhs, height: lhs.height / rhs)
}

/// Returns lhs divided by rhs.
public func /(_ lhs: CGSize, _ rhs: Double) -> CGSize {
	return CGSize(width: lhs.width / CGFloat(rhs), height: lhs.height / CGFloat(rhs))
}

/// Divides lhs by rhs.
public func /=(_ lhs: inout CGSize, _ rhs: CGFloat) {
	lhs.width /= rhs
	lhs.height /= rhs
}

/// Divides lhs by rhs.
public func /=(_ lhs: inout CGSize, _ rhs: Double) {
	lhs.width /= CGFloat(rhs)
	lhs.height /= CGFloat(rhs)
}

/// Adds two CGSizes.
public func +(_ lhs: CGSize, _ rhs: CGSize) -> CGSize {
	return CGSize(width: lhs.width + rhs.width, height: lhs.height + rhs.width)
}

/// Adds two CGSizes.
public func +=(_ lhs: inout CGSize, _ rhs: CGSize) {
	lhs.width += rhs.width
	lhs.height += rhs.height
}

public extension CGSize {
	
	/// Creates a size with both width and height being set to dimension.
	init(dimension: CGFloat) {
		self.init(width: dimension, height: dimension)
	}
	
	/// Returns a copy of self that contains integral width and height.
	var integral: CGSize {
		return CGSize(width: Int(self.width), height: Int(self.height))
	}
	
	/// Returns true if both width and height is zero.
	var isEmpty: Bool {
		return self.height.isZero && self.width.isZero
	}
	
	/// Takes self and proportinally changes it to fit `otherSize`. If `allowScaleUp`
	/// is true (default), smaller size will be enlarged.
	func fitting(into otherSize: CGSize, scalingUp: Bool = true) -> CGSize {
		if !scalingUp && self.width < otherSize.width && self.height < otherSize.height {
			// Don't scale up!
			return self
		}

		if self.width / self.height > otherSize.width / otherSize.height {
			// Wider
			return CGSize(width: otherSize.width, height: self.height * (otherSize.width / self.width))
		} else {
			// Taller
			return CGSize(width: self.width * (otherSize.height / self.height), height: otherSize.height)
		}
	}
	
	@available(*, deprecated, renamed: "fitting(into:)")
	func proportionalSizeToFit(in otherSize: CGSize) -> CGSize {
		return self.fitting(into: otherSize)
	}

	
}
