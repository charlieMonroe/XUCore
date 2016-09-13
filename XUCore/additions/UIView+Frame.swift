//
//  UIView+Frame.swift
//  XUCore
//
//  Created by Charlie Monroe on 11/30/15.
//  Copyright © 2015 Charlie Monroe Software. All rights reserved.
//

import Foundation

public extension UIView {
	
	/// Frame origin.
	@available(*, deprecated, message: "Use Swift's ability to update struct parts.")
	public var frameOrigin: CGPoint {
		get {
			return self.frame.origin
		}
		set {
			self.frame.origin = newValue
		}
	}
	
	/// Frame size.
	@available(*, deprecated, message: "Use Swift's ability to update struct parts.")
	public var frameSize: CGSize {
		get {
			return self.frame.size
		}
		set {
			self.frame.size = newValue
		}
	}
	
	/// Height.
	@available(*, deprecated, message: "Use Swift's ability to update struct parts.")
	public var height: CGFloat {
		get {
			return self.frame.height
		}
		set {
			self.frame.size.height = newValue
		}
	}
	
	/// Width.
	@available(*, deprecated, message: "Use Swift's ability to update struct parts.")
	public var width: CGFloat {
		get {
			return self.frame.width
		}
		set {
			self.frame.size.width = newValue
		}
	}
	
	/// X of the frame.
	@available(*, deprecated, message: "Use Swift's ability to update struct parts.")
	public var x: CGFloat {
		get {
			return self.frame.minX
		}
		set {
			self.frame.origin.x = newValue
		}
	}
	
	/// Y of the frame.
	@available(*, deprecated, message: "Use Swift's ability to update struct parts.")
	public var y: CGFloat {
		get {
			return self.frame.minY
		}
		set {
			self.frame.origin.y = newValue
		}
	}
	
}
