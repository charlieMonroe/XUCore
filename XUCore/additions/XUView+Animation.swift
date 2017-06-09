//
//  XUView+Animation.swift
//  XUCore
//
//  Created by Charlie Monroe on 6/8/17.
//  Copyright © 2017 Charlie Monroe Software. All rights reserved.
//

import Foundation

#if os(iOS)
	import UIKit
#else
	import Cocoa
#endif


/// A structure that gathers some view animations. You can gather several views
/// an perform the same animation them using this as well.
public struct XUViewAnimation<T: __XUBridgedView> {
	
	/// Views this was initialized with.
	public let views: [T]
	
	/// Creates an instance of this structure with a single view.
	public init(view: T) {
		self.init(views: [view])
	}
	
	/// Creates an instance of this structure with several views.
	public init(views: [T]) {
		self.views = views
	}
	
}

public extension __XUBridgedView {
	
	/// Returns an animation structure that gathers some animations. Ideally,
	/// this would return XUViewAnimation<Self>, once the generics get to that
	/// point. If you need animations that are only on certain subclasses,
	/// create XUViewAnimation instance yourself.
	///
	/// Usage: e.g. view.animation.wobble()
	public var animation: XUViewAnimation<__XUBridgedView> {
		return XUViewAnimation(view: self)
	}
	
}

public extension Array where Element : __XUBridgedView {
	
	/// Returns an animation structure that gathers some animations.
	///
	/// Usage: e.g. views.animation.wobble()
	public var animation: XUViewAnimation<Element> {
		return XUViewAnimation(views: self)
	}
	
}

public extension XUViewAnimation {
	
	/// Animates a wobbling movement indicating that the value is invalid. Note
	/// that since it's layer-based animation, the view must be layer-backed on
	/// macOS, otherwise is ignored. Patches are welcome.
	public func wobble() {
		for view in self.views {
			// Layer is optional on macOS.
			let layer: CALayer
			#if os(iOS)
				layer = view.layer
			#else
				guard let viewLayer = view.layer else {
					continue
				}
				
				layer = viewLayer
			#endif
			
			let positionX: CGFloat = layer.position.x
			let bounceAnimation = CAKeyframeAnimation(keyPath: "position.x")
			bounceAnimation.values = [positionX, positionX + 3.0, positionX - 2.0, positionX + 1.0, positionX]
			bounceAnimation.duration = 0.25
			
			layer.add(bounceAnimation, forKey: "wobble")
		}
	}
	
}

