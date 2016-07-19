//
//  CGGraphicsAdditions.swift
//  XUCore
//
//  Created by Charlie Monroe on 3/1/16.
//  Copyright © 2016 Charlie Monroe Software. All rights reserved.
//

import Foundation

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
	@warn_unused_result
	public func centerRect(rect: CGRect) -> CGRect {
		let origin = CGPoint(x: self.minX + (self.width - rect.width) / 2.0, y: self.minY + (self.height - rect.height) / 2.0)
		return CGRect(origin: origin, size: rect.size)
	}
	
	/// Returns top half. Top by coordinates, doesn't take into account flipped
	/// graphics context.
	public var topHalf: CGRect {
		return CGRect(x: self.minX, y: self.midY, width: self.width, height: self.height)
	}

}


public extension CGSize {
	
	public var isEmpty: Bool {
		return self.height.isZero && self.width.isZero
	}
	
}
