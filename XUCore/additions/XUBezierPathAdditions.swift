//
//  XUBezierPathAdditions.swift
//  XUCore
//
//  Created by Charlie Monroe on 7/14/16.
//  Copyright © 2016 Charlie Monroe Software. All rights reserved.
//

import Foundation

#if os(iOS)
	import UIKit
	
	public typealias __XUBezierPath = UIBezierPath
#else
	import Cocoa
	
	public typealias __XUBezierPath = NSBezierPath
#endif

public enum XUDirection: Int {
	case LeftToRight
	case RightToLeft
	case BottomToTop
	case TopToBottom
	
	#if os(OSX)
	
	/// If the context is flipped, the opposite direction is returned for bottom/
	/// top.
	public var directionInCurrentGraphicsContext: XUDirection {
		guard let graphicsContext = NSGraphicsContext.currentContext() where graphicsContext.flipped else {
			return self
		}
		
		if self.isVertical {
			return self.opposite
		}
	
		return self
	}
	
	#endif
	
	/// Returns true if self == .LeftToRight or .RightToLeft
	public var isHorizontal: Bool {
		return self == .LeftToRight || self == .RightToLeft
	}
	
	/// Returns true if self == .TopToBottom or .BottomToTop
	public var isVertical: Bool {
		return self == .TopToBottom || self == .BottomToTop
	}
	
	/// Returns opposite direction.
	public var opposite: XUDirection {
		switch self {
		case .LeftToRight:
			return .RightToLeft
		case .RightToLeft:
			return .LeftToRight
		case .TopToBottom:
			return .BottomToTop
		case .BottomToTop:
			return .TopToBottom
		}
	}
}

public extension __XUBezierPath {
	
	private func _addLineToPoint(point: CGPoint) {
		#if os(OSX)
			self.lineToPoint(point)
		#else
			self.addLineToPoint(point)
		#endif
	}
	
	public convenience init(triangleInRect rect: CGRect, direction: XUDirection) {
		self.init()
		
		let correctDirection: XUDirection
		#if os(OSX)
			correctDirection = direction.directionInCurrentGraphicsContext
		#else
			if direction.isVertical {
				// In OS X's sense, the context is flipped
				correctDirection = direction.opposite
			} else {
				correctDirection = direction
			}
		#endif
		switch correctDirection {
		case .BottomToTop:
			self.moveToPoint(CGPoint(x: rect.minX, y: rect.minY))
			self._addLineToPoint(CGPoint(x: rect.maxX, y: rect.minY))
			self._addLineToPoint(CGPoint(x: rect.minX + (rect.maxX - rect.minX) / 2.0, y: rect.maxY))
		case .TopToBottom:
			self.moveToPoint(CGPoint(x: rect.minX, y: rect.maxY))
			self._addLineToPoint(CGPoint(x: rect.maxX, y: rect.maxY))
			self._addLineToPoint(CGPoint(x: rect.minX + (rect.maxX - rect.minX) / 2.0, y: rect.minY))
		case .RightToLeft:
			self.moveToPoint(CGPoint(x: rect.minX, y: rect.maxY))
			self._addLineToPoint(CGPoint(x: rect.minX, y: rect.minY))
			self._addLineToPoint(CGPoint(x: rect.maxX, y: rect.minY + (rect.maxY - rect.minY) / 2.0))
		case .LeftToRight:
			self.moveToPoint(CGPoint(x: rect.maxX, y: rect.maxY))
			self._addLineToPoint(CGPoint(x: rect.maxX, y: rect.minY))
			self._addLineToPoint(CGPoint(x: rect.minX, y: rect.minY + (rect.maxY - rect.minY) / 2.0))
		}
		
		self.closePath()
	}
	
}
