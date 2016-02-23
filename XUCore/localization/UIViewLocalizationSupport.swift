//
//  UIViewLocalizationSupport.swift
//  XUCore
//
//  Created by Charlie Monroe on 11/10/15.
//  Copyright © 2015 Charlie Monroe Software. All rights reserved.
//

import Foundation

public extension UIButton {
	public override func localizeView(bundle: NSBundle = XUMainBundle) {
		if let title = self.titleForState(.Normal) {
			self.setTitle(XULocalizedString(title, inBundle: bundle), forState: .Normal)
		}
	}
}
public extension UILabel {
	public override func localizeView(bundle: NSBundle = XUMainBundle) {
		if let text = self.text {
			self.text = XULocalizedString(text, inBundle: bundle)
		}
	}
}
public extension UITextField {
	public override func localizeView(bundle: NSBundle = XUMainBundle) {
		if let originalPlaceholder = self.attributedPlaceholder {
			let attributes = originalPlaceholder.attributesAtIndex(0, effectiveRange: nil)
			self.attributedPlaceholder = NSAttributedString(string: XULocalizedString(originalPlaceholder.string, inBundle: bundle), attributes: attributes)
		} else {
			// No attributed placeholder
			if let placeholder = self.placeholder {
				self.placeholder = XULocalizedString(placeholder, inBundle: bundle)
			}
		}
	}
}
public extension UIView {
	public func localizeView(bundle: NSBundle = XUMainBundle) {
		for view in self.subviews {
			view.localizeView(bundle)
		}
	}
}
