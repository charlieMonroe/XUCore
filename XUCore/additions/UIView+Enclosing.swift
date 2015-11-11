//
//  UIView+Enclosing.swift
//  XUCore
//
//  Created by Charlie Monroe on 11/10/15.
//  Copyright © 2015 Charlie Monroe Software. All rights reserved.
//

import Foundation

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
	
}

