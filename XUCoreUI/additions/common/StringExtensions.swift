//
//  StringExtensions.swift
//  XUCoreUI
//
//  Created by Charlie Monroe on 3/20/19.
//  Copyright © 2019 Charlie Monroe Software. All rights reserved.
//

import Foundation
#if os(macOS)
	import AppKit
#else
	import UIKit
#endif

extension String {
	
	/// Draws `self` centered in rect with attributes.
	@discardableResult
	public func draw(centeredIn rect: CGRect, withAttributes atts: [NSAttributedString.Key : Any] = [:]) -> CGRect {
		let stringSize = self.size(withAttributes: atts, maximumWidth: rect.width)
		var frame = rect
		frame.size = stringSize
		frame = rect.centeringRectInSelf(frame)
		self.draw(in: frame, withAttributes: atts)
		return frame
	}

	/// Draws `self` aligned right to point. Returns size of the drawn string.
	@discardableResult
	public func draw(rightAlignedTo point: CGPoint, withAttributes atts: [NSAttributedString.Key : Any]? = nil) -> CGSize {
		let s = self.size(withAttributes: atts)
		self.draw(at: CGPoint(x: point.x - s.width, y: point.y), withAttributes: atts)
		return s
	}
	
	/// Calls `replacingOccurrences(of:with:)` for each key-value pair.
	public func replacingOccurrences(with mapping: [String : String]) -> String {
		var result = self
		for (key, value) in mapping {
			result = result.replacingOccurrences(of: key, with: value)
		}
		return result
	}
	
	/// Returns size with attributes, limited to width.
	public func size(withAttributes attrs: [NSAttributedString.Key : Any], maximumWidth width: CGFloat) -> CGSize {
		let constraintSize = CGSize(width: width, height: CGFloat.greatestFiniteMagnitude)
		#if os(iOS)
			return self.boundingRect(with: constraintSize, options: .usesLineFragmentOrigin, attributes: attrs, context: nil).size
		#else
			return self.boundingRect(with: constraintSize, options: .usesLineFragmentOrigin, attributes: attrs).size
		#endif
	}
	
	/// Truncates the string in the middle with '...' in order to fit the width,
	/// similarily as NSTextField does.
	public func truncatingMiddle(toFitWidth width: CGFloat, withAttributes atts: [NSAttributedString.Key : Any]) -> String {
		var front = Substring()
		var tail = Substring()
		
		var frontIndex = self.index(self.startIndex, offsetBy: self.count / 2)
		var tailIndex = frontIndex
		
		var result = self
		var size = self.size(withAttributes: atts)
		
		while size.width > width {
			autoreleasepool {
				frontIndex = self.index(before: frontIndex)
				tailIndex = self.index(after: tailIndex)
				
				front = self[..<frontIndex]
				tail = self[tailIndex...]
				result = "\(front)...\(tail)"
				
				size = result.size(withAttributes: atts)
			}
		}
		return result
	}
	
}
