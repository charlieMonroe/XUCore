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
			self.setTitle(FCLocalizedString(title), forState: .Normal)
		}
	}
}
public extension UILabel {
	public override func localizeView() {
		if let text = self.text {
			self.text = FCLocalizedString(text)
		}
	}
}
public extension UITextField {
	public override func localizeView() {
		if let placeholder = self.placeholder {
			self.placeholder = FCLocalizedString(placeholder)
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
