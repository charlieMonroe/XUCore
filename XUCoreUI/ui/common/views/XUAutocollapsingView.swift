//
//  XUAutocollapsingView.swift
//  UctoX
//
//  Created by Charlie Monroe on 12/20/15.
//  Copyright © 2015 Charlie Monroe Software. All rights reserved.
//

import Foundation
#if os(macOS)
	import AppKit
#else
	import UIKit

private extension NSLayoutConstraint {
	
	func conditionalAnimator(_ animated: Bool) -> Self {
		return self
	}
	
}

#endif

/// This view will automatically find its height constraint (will throw 
/// an exception if it doesn't) and will set it to 0.0 when hidden and restore
/// its previous value if not.
open class XUAutocollapsingView: __XUBridgedView {

	/// Original height. This is lazily set when the view is hidden. You can
	/// optionally set a different value here, though note that it has only effect
	/// when the view is hidden and then re-shown.
	public var originalHeight: CGFloat = 0.0

	/// Marked as YES on -initWithCoder: and NO at the end. Needed because layout
	/// constraints aren't loaded yet.
	private var _inCoderInit: Bool = true
	
	/// Called from -setHidden: to perform hide or unhide.
	private func _performHide(_ hidden: Bool, animated: Bool) {
		guard let constraint = self.collapsibleContstraint else {
			return
		}
		
		if hidden {
			if constraint.constant == 0.0 {
				return
			}
			
			self.originalHeight = constraint.constant
			constraint.conditionalAnimator(animated).constant = 0.0
		} else {
			if constraint.constant == self.originalHeight {
				return
			}
			
			constraint.conditionalAnimator(animated).constant = self.originalHeight
		}
		
		if animated {
			#if os(iOS)
			UIView.animate(withDuration: CATransaction.animationDuration()) {
				self.superview?.layoutSubviews()
			}
			#else
			self.superview?.animator().layout()
			#endif
		} else {
		#if os(iOS)
			self.superview?.setNeedsLayout()
		#else
			self.superview?.needsLayout = true
		#endif
		}
	}
	
	open override func awakeFromNib() {
		super.awakeFromNib()
		
		if self.isHidden {
			self._performHide(true, animated: false)
		}
	}
	
	/// Returns the constraint that is collapsible. It will return nil before
	/// the view is loaded from XIB.
	open var collapsibleContstraint: NSLayoutConstraint! {
		let constraint = self.constraints.first(where: { $0.firstAttribute == .height })
		if constraint == nil && !_inCoderInit {
			fatalError("XUAutocollapsingView needs to have a collapsible constraint!")
		}
		
		return constraint
	}
	
	public override init(frame: CGRect) {
		super.init(frame: frame)
	}
	
	public required init?(coder: NSCoder) {
		super.init(coder: coder)
		
		_inCoderInit = false
	}
	
	open override var isHidden: Bool {
		get {
			return super.isHidden
		}
		set {
			if newValue == self.isHidden {
				// No action
				return
			}
			
			self._performHide(newValue, animated: false)
			super.isHidden = newValue
		}
	}
	
	#if os(macOS)
	public func animateHidden(_ hidden: Bool, animateAlpha: Bool = false) {
		if self.isHidden {
			super.isHidden = false
			
			if animateAlpha {
				self.alphaValue = 0.0
				self.animator().alphaValue = 1.0
			}
			self._performHide(hidden, animated: true)
		} else {
			if animateAlpha {
				self.animator().alphaValue = 0.0
			}
			self._performHide(hidden, animated: true)
			
			DispatchQueue.main.asyncAfter(deadline: .seconds(CATransaction.animationDuration())) {
				super.isHidden = false
				
				if animateAlpha {
					self.alphaValue = 1.0
				}
			}
		}
	}
	#endif
	
}

