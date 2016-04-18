//
//  XUAutocollapsingView.swift
//  UctoX
//
//  Created by Charlie Monroe on 12/20/15.
//  Copyright © 2015 Charlie Monroe Software. All rights reserved.
//

import Foundation

/// This view will automatically find its height constraint (will throw 
/// an exception if it doesn't) and will set it to 0.0 when hidden and restore
/// its previous value if not.
public class XUAutocollapsingView: __XUBridgedView {
	
	private var _originalHeight: CGFloat = 0.0
	
	/// Marked as YES on -initWithCoder: and NO at the end. Needed because layout
	 /// constraints aren't loaded yet.
	private var _inCoderInit: Bool = true
	
	private var _heightContstraint: NSLayoutConstraint? {
		let constraint = self.constraints.find({ $0.firstAttribute == .Height })
		if constraint == nil && !_inCoderInit {
			NSException(name: NSInternalInconsistencyException, reason: "XUAutocollapsingView needs to have a height constraint!", userInfo: nil).raise()
		}
		return constraint
	}
	
	/// Called from -setHidden: to perform hide or unhide.
	private func _performHide(hidden: Bool) {
		guard let constraint = self._heightContstraint else {
			return
		}
		
		if hidden {
			_originalHeight = constraint.constant
			constraint.constant = 0.0
		} else {
			constraint.constant = _originalHeight
		}
		
		#if os(iOS)
			self.superview?.setNeedsLayout()
		#else
			self.superview?.needsLayout = true
		#endif
	}
	
	public override func awakeFromNib() {
		super.awakeFromNib()
		
		if self.hidden {
			self._performHide(true)
		}
	}
	
	public required init?(coder: NSCoder) {
		super.init(coder: coder)
		
		_inCoderInit = false
	}
	
	public override var hidden: Bool {
		get {
			return super.hidden
		}
		set {
			if newValue == self.hidden {
				// No action
				return
			}
			
			self._performHide(newValue)
			super.hidden = newValue
		}
	}
	
}

