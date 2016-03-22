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
	public var frameOrigin: CGPoint {
		get {
			return self.frame.origin
		}
		set {
			self.frame.origin = newValue
		}
	}
	
	/// Frame size.
	public var frameSize: CGSize {
		get {
			return self.frame.size
		}
		set {
			self.frame.size = newValue
		}
	}
	
	/// Height.
	public var height: CGFloat {
		get {
			return self.frame.height
		}
		set {
			self.frame.size.height = newValue
		}
	}
	
	/// Width.
	public var width: CGFloat {
		get {
			return self.frame.width
		}
		set {
			self.frame.size.width = newValue
		}
	}
	
	/// X of the frame.
	public var x: CGFloat {
		get {
			return self.frame.minX
		}
		set {
			self.frame.origin.x = newValue
		}
	}
	
	/// Y of the frame.
	public var y: CGFloat {
		get {
			return self.frame.origin.y
		}
		set {
			self.frame.origin.y = newValue
		}
	}
	
}
