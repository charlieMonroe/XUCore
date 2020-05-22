//
//  XUScrollViewKeyboardInsetManager.swift
//  XUCore
//
//  Created by Charlie Monroe on 6/8/17.
//  Copyright © 2017 Charlie Monroe Software. All rights reserved.
//

import UIKit

/// A simple class that initializes with a scroll view and updates its insets
/// when a keyboard is shown.
public class XUScrollViewKeyboardInsetManager {
	
	/// Scroll view this was initialized with.
	public weak var scrollView: UIScrollView!
	
	
	@objc private func _didChangeKeyboard(_ notification: Notification) {
		self._updateScrollViewInset(from: notification)
	}
	
	@objc private func _didHideKeyboard(_ notification: Notification) {
		self._updateScrollViewInset(from: notification)
	}
	
	@objc private func _didShowKeyboard(_ notification: Notification) {
		self._updateScrollViewInset(from: notification)
	}
	
	private func _updateScrollViewInset(from keyboardNotification: Notification) {
		guard let keyboardFrame = keyboardNotification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else {
			return
		}
		
		if keyboardNotification.name == UIResponder.keyboardDidHideNotification {
			self.scrollView.contentInset.bottom = 0.0
		} else {
			if self.scrollView.contentInset.bottom != keyboardFrame.height {
				self.scrollView.contentInset.bottom = keyboardFrame.height
			}
		}
	}
	
	/// Init with a scroll view that should be observed.
	public init(scrollView: UIScrollView) {
		self.scrollView = scrollView
		
		NotificationCenter.default.addObserver(self, selector: #selector(_didChangeKeyboard(_:)), name: UIResponder.keyboardDidChangeFrameNotification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(_didHideKeyboard(_:)), name: UIResponder.keyboardDidHideNotification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(_didShowKeyboard(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
	}
	
}

