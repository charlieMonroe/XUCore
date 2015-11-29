//
//  UIViewLocalizationSupport.swift
//  XUCore
//
//  Created by Charlie Monroe on 11/10/15.
//  Copyright © 2015 Charlie Monroe Software. All rights reserved.
//

import Foundation

public extension UIButton {
	public override func localizeView() {
		if let title = self.titleForState(.Normal) {
			self.setTitle(XULocalizedString(title), forState: .Normal)
		}
	}
}
public extension UILabel {
	public override func localizeView() {
		if let text = self.text {
			self.text = XULocalizedString(text)
		}
	}
}
public extension UITextField {
	public override func localizeView() {
		if let originalPlaceholder = self.attributedPlaceholder {
			let attributes = originalPlaceholder.attributesAtIndex(0, effectiveRange: nil)
			self.attributedPlaceholder = NSAttributedString(string: XULocalizedString(originalPlaceholder.string), attributes: attributes)
		}else{
			// No attributed placeholder
			if let placeholder = self.placeholder {
				self.placeholder = XULocalizedString(placeholder)
			}
		}
	}
}
public extension UIView {
	public func localizeView() {
		for view in self.subviews {
			view.localizeView()
		}
	}
}
