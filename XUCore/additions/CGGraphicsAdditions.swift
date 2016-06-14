//
//  CGGraphicsAdditions.swift
//  XUCore
//
//  Created by Charlie Monroe on 3/1/16.
//  Copyright © 2016 Charlie Monroe Software. All rights reserved.
//

import Foundation

public extension CGRect {
	
	public var center: CGPoint {
		return CGPoint(x: self.midX, y: self.midY)
	}
	
}


public extension CGSize {
	
	public var isEmpty: Bool {
		return self.height.isZero && self.width.isZero
	}
	
}
