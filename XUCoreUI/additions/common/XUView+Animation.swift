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

public struct XUViewAnimationDuration {
	
	/// Duration for hideWithFadeOut and showWithFadeIn.
	public static let fadeAnimationDuration: TimeInterval = 0.5

}

public extension __XUBridgedView {
	
	/// Returns an animation structure that gathers some animations. Ideally,
	/// this would return XUViewAnimation<Self>, once the generics get to that
	/// point. If you need animations that are only on certain subclasses,
	/// create XUViewAnimation instance yourself.
	///
	/// Usage: e.g. view.animation.wobble()
	var animation: XUViewAnimation<__XUBridgedView> {
		return XUViewAnimation(view: self)
	}
	
}

#if os(macOS)
public extension NSAnimatablePropertyContainer {
	
	/// Returns either self.animator() or self depending on the `animate`
	/// parameter. This is useful if you need to layout some UI and sometimes
	/// it is with animation and sometimes it isn't.
	///
	/// - Parameter animate: Whether to animate.
	/// - Returns: Self or a animator proxy.
	func conditionalAnimator(_ animate: Bool) -> Self {
		if animate {
			return self.animator()
		} else {
			return self
		}
	}
	
}
#endif

public extension Array where Element : __XUBridgedView {
	
	/// Returns an animation structure that gathers some animations.
	///
	/// Usage: e.g. views.animation.wobble()
	var animation: XUViewAnimation<Element> {
		return XUViewAnimation(views: self)
	}
	
}

private typealias _XUPulsationProgress = (progress: Double, direction: Bool)
private var _pulsatingViews: [__XUBridgedView : (timer: Timer, progress: _XUPulsationProgress)] = [:]
private let _pulsatingViewsFPS: TimeInterval = 1.0 / 30.0

public extension XUViewAnimation {
	
	#if os(macOS)
	private func _animateAlphaUsingTimer(from sourceAlpha: CGFloat, to targetAlpha: CGFloat, completion: (() -> Void)? = nil) {
		let animationDuration: TimeInterval = XUViewAnimationDuration.fadeAnimationDuration
		let targetFPS = 30.0
		let step = animationDuration / targetFPS
		let numberOfSteps = Int(animationDuration * targetFPS)
		
		self.views.forEach({ $0.alphaValue = sourceAlpha })
		let alphaStep = (targetAlpha - sourceAlpha) /  CGFloat(numberOfSteps)
		
		var stepCounter = 0
		let timer = Timer.scheduledTimer(withTimeInterval: step, repeats: true) { (timer) in
			stepCounter += 1
			
			self.views.forEach({ $0.alphaValue += alphaStep })
			
			if stepCounter == numberOfSteps {
				self.views.forEach({ $0.alphaValue = targetAlpha })
				timer.invalidate()
				
				completion?()
			}
		}
		RunLoop.current.add(timer, forMode: RunLoop.Mode.modalPanel)
		RunLoop.current.add(timer, forMode: RunLoop.Mode.eventTracking)
	}
	#endif
	
	private func _updatePulsating(for view: __XUBridgedView) {
		guard var viewSetup = _pulsatingViews[view] else {
			return
		}
		
		let delta: Double
		if viewSetup.progress.direction {
			delta = _pulsatingViewsFPS
		} else {
			delta = -_pulsatingViewsFPS
		}
		
		let x = viewSetup.progress.progress + delta
		if x < 0.0 || x > 1.0 {
			viewSetup.progress.direction = !viewSetup.progress.direction
			_pulsatingViews[view] = viewSetup
			
			self._updatePulsating(for: view)
			return
		}
		
		let easeInOutProgress = x < 0.5 ? 2.0 * x * x : -1.0 + (4.0 - 2.0 * x) * x
		let alpha = 0.25 + (easeInOutProgress * 0.75)
		
		viewSetup.progress.progress = x
		_pulsatingViews[view] = viewSetup
		
		#if os(iOS)
			view.alpha = CGFloat(alpha)
		#else // macOS
			view.alphaValue = CGFloat(alpha)
		#endif
	}
	
	/// Hides the views by fading them out and then setting isHidden to true.
	func hideWithFadeOut(completionHandler: @escaping () -> Void = {}) {
		print("Hide - \(self.views)")
		#if os(macOS)
			self._animateAlphaUsingTimer(from: 1.0, to: 0.0, completion: {
				self.views.forEach({
					guard $0.alphaValue == 0.0 else {
						return // Something else is modifying it already.
					}
					
					$0.isHidden = true
				})
				
				completionHandler()
			})
		#else
			UIView.animate(withDuration: XUViewAnimationDuration.fadeAnimationDuration, animations: {
				self.views.forEach({ $0.alpha = 0.0 })
			}, completion: { _ in
				self.views.forEach({
					guard $0.alpha == 0.0 else {
						return // Something else is modifying it already.
					}
					
					$0.isHidden = true
				})
				
				completionHandler()
			})
		#endif
	}
	
	/// This is a convenience shortcut to hideWithFadeOut and showWithFadeIn.
	var isHidden: Bool {
		get {
			return self.views.isHidden
		}
		nonmutating set {
			guard newValue != self.isHidden else {
				return
			}
			
			if newValue {
				self.hideWithFadeOut()
			} else {
				self.showWithFadeIn()
			}
		}
	}
	
	/// Shows the views by fading them in and then setting isHidden to false.
	func showWithFadeIn(completionHandler: @escaping () -> Void = {}) {
		print("Show - \(self.views)")
		#if os(macOS)
			self.views.forEach({
				$0.alphaValue = 0.0
				$0.isHidden = false
			})
			
			self._animateAlphaUsingTimer(from: 0.0, to: 1.0, completion: completionHandler)
		#else
			self.views.forEach({
				$0.alpha = 0.0
				$0.isHidden = false
			})
		
			UIView.animate(withDuration: XUViewAnimationDuration.fadeAnimationDuration, animations: {
				self.views.forEach({ $0.alpha = 1.0 })
			}, completion: { (_) in
				completionHandler()
			})
		#endif
	}
	
	/// Starts pulsating, if it's not already. Pulsating view will decrease and
	/// increase its opacity. Note that a strong reference is kept for the views.
	func startPulsating() {
		for view in self.views {
			guard _pulsatingViews[view] == nil else {
				continue // Already pulsating.
			}
			
			let timer = Timer(timeInterval: _pulsatingViewsFPS, repeats: true, block: { (_) in
				self._updatePulsating(for: view)
			})
			
			#if os(macOS)
				RunLoop.current.add(timer, forMode: RunLoop.Mode.default)
				RunLoop.current.add(timer, forMode: RunLoop.Mode.eventTracking)
				RunLoop.current.add(timer, forMode: RunLoop.Mode.modalPanel)
			#endif
			
			_pulsatingViews[view] = (timer, _XUPulsationProgress(1.0, false))
		}
	}
	
	/// Stops pulsating.
	func stopPulsating() {
		for view in self.views {
			#if os(iOS)
				view.alpha = 1.0
			#else
				view.alphaValue = 1.0
			#endif
			
			guard let viewSetup = _pulsatingViews[view] else {
				return
			}
			
			viewSetup.timer.invalidate()
			_pulsatingViews[view] = nil
		}
	}
	
	
	/// Animates a wobbling movement indicating that the value is invalid. Note
	/// that since it's layer-based animation, the view must be layer-backed on
	/// macOS, otherwise is ignored. Patches are welcome.
	func wobble() {
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
			bounceAnimation.values = [positionX, positionX + 6.0, positionX - 4.0, positionX + 2.0, positionX]
			bounceAnimation.duration = 0.25
			
			layer.add(bounceAnimation, forKey: "wobble")
		}
	}
	
}

#if os(macOS)
	
	/// We need to keep track of the last set string value. The animation context
	/// doesn't necessarily keep the order of invocations, so if there are several
	/// animation requests within a single run loop, we may end up with a wrong
	/// value in the field.
	private var _textFieldValues: [NSTextField : String] = [:]
	
	public extension XUViewAnimation where T: NSTextField {
		
		/// Animates text change in a text field. Should only be used on text fields
		/// that act as labels.
		func setStringValueAnimated(_ stringValue: String, duration: TimeInterval = 0.5) {
			for field in self.views {
				if let targetValue = _textFieldValues[field] {
					if targetValue == stringValue {
						// It's the same value, skip.
						continue
					}
				} else {
					// We're not animating.
					if field.stringValue == stringValue {
						// It's the same value, skip.
						continue
					}
				}
				
				_textFieldValues[field] = stringValue
				
				NSAnimationContext.runAnimationGroup({ (context) in
					context.duration = duration
					context.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeOut)
					field.animator().alphaValue = 0.0
				}, completionHandler: {
					if let string = _textFieldValues[field] {
						field.stringValue = string
						_textFieldValues[field] = nil
					}
					
					NSAnimationContext.runAnimationGroup({ (context) in
						context.duration = duration
						context.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeOut)
						field.animator().alphaValue = 1.0
					}, completionHandler: nil)
				})
			}
		}
		
	}
	
	/// We need to keep track of the target length for each status item in case
	/// it changes before the animation is complete.
	private var _statusItemValues: [NSStatusItem : _XUStatusItemAnimationDelegate] = [:]
	
	/// The animation delegate.
	private class _XUStatusItemAnimationDelegate: NSObject, NSAnimationDelegate {
		
		/// Animation.
		let animation: NSAnimation = NSAnimation(duration: 0.25, animationCurve: .easeInOut)
		
		/// Original length of the item.
		let originalLength: CGFloat
		
		/// Status item.
		let statusItem: NSStatusItem
		
		/// Target length of the item.
		var targetLength: CGFloat
		
		
		func animationDidEnd(_ animation: NSAnimation) {
			self.statusItem.length = self.targetLength
			_statusItemValues[self.statusItem] = nil
		}
		
		func animation(_ animation: NSAnimation, didReachProgressMark progress: NSAnimation.Progress) {
			let delta = self.targetLength - self.originalLength
			let currentDelta = delta * CGFloat(progress)
			self.statusItem.length = self.originalLength + currentDelta
		}
				
		init(statusItem: NSStatusItem, targetLength: CGFloat) {
			self.originalLength = statusItem.length
			self.statusItem = statusItem
			self.targetLength = targetLength
			
			super.init()
			
			stride(from: Float(0.0), to: Float(1.0), by: 0.1).forEach({ self.animation.addProgressMark($0) })
			
			self.animation.animationBlockingMode = .nonblocking
			self.animation.delegate = self
		}
		
	}
	
	public extension NSStatusItem {
		
		/// Animates self to a certain length.
		func animate(to length: CGFloat) {
			if let delegate = _statusItemValues[self] {
				delegate.animation.stop()
			}
			
			if self.length == length {
				return
			}
			
			let delegate = _XUStatusItemAnimationDelegate(statusItem: self, targetLength: length)
			_statusItemValues[self] = delegate
			
			delegate.animation.start()
		}
		
	}
	
#endif


