//
//  UIView+Enclosing.swift
//  XUCore
//
//  Created by Charlie Monroe on 11/10/15.
//  Copyright © 2015 Charlie Monroe Software. All rights reserved.
//

import Foundation
import UIKit

public extension UIView {
	
	private func _enclosingView<T: UIView>() -> T? {
		var view: UIView? = self
		while view != nil {
			if let targetView = view as? T {
				return targetView
			}
			
			view = view!.superview
		}
		return nil
	}
	
	public var enclosingScrollView: UIScrollView? {
		return self._enclosingView()
	}
	public var enclosingTableView: UITableView? {
		return self._enclosingView()
	}
	public var enclosingTableViewCell: UITableViewCell? {
		return self._enclosingView()
	}

	
	/// Returns the first responder, if there is one in the subview hierarchy.
	public var firstResponder: UIView? {
		if self.isFirstResponder {
			return self
		}
		
		for view in self.subviews {
			if let responder = view.firstResponder {
				return responder
			}
		}
		
		return nil
	}
	
	/// Determines whether the view is within the subview hierarchy of `view`.
	public func isChild(of view: UIView) -> Bool {
		var superview = self.superview
		while superview != nil {
			if superview === view {
				return true
			}
			
			superview = superview?.superview
		}
		
		return false
	}
	
}

