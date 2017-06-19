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
	case leftToRight
	case rightToLeft
	case bottomToTop
	case topToBottom
	
	#if os(OSX)
	
	/// If the context is flipped, the opposite direction is returned for bottom/
	/// top.
	public var directionInCurrentGraphicsContext: XUDirection {
		guard let graphicsContext = NSGraphicsContext.current , graphicsContext.isFlipped else {
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
		return self == .leftToRight || self == .rightToLeft
	}
	
	/// Returns true if self == .TopToBottom or .BottomToTop
	public var isVertical: Bool {
		return self == .topToBottom || self == .bottomToTop
	}
	
	/// Returns opposite direction.
	public var opposite: XUDirection {
		switch self {
		case .leftToRight:
			return .rightToLeft
		case .rightToLeft:
			return .leftToRight
		case .topToBottom:
			return .bottomToTop
		case .bottomToTop:
			return .topToBottom
		}
	}
}

public extension __XUBezierPath {
	
	private func _addLine(to point: CGPoint) {
		#if os(OSX)
			self.line(to: point)
		#else
			self.addLine(to: point)
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
		case .bottomToTop:
			self.move(to: CGPoint(x: rect.minX, y: rect.minY))
			self._addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
			self._addLine(to: CGPoint(x: rect.minX + (rect.maxX - rect.minX) / 2.0, y: rect.maxY))
		case .topToBottom:
			self.move(to: CGPoint(x: rect.minX, y: rect.maxY))
			self._addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
			self._addLine(to: CGPoint(x: rect.minX + (rect.maxX - rect.minX) / 2.0, y: rect.minY))
		case .rightToLeft:
			self.move(to: CGPoint(x: rect.minX, y: rect.maxY))
			self._addLine(to: CGPoint(x: rect.minX, y: rect.minY))
			self._addLine(to: CGPoint(x: rect.maxX, y: rect.minY + (rect.maxY - rect.minY) / 2.0))
		case .leftToRight:
			self.move(to: CGPoint(x: rect.maxX, y: rect.maxY))
			self._addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
			self._addLine(to: CGPoint(x: rect.minX, y: rect.minY + (rect.maxY - rect.minY) / 2.0))
		}
		
		self.close()
	}
	
}
