//
//  UIViewLocalizationSupport.swift
//  XUCore
//
//  Created by Charlie Monroe on 11/10/15.
//  Copyright © 2015 Charlie Monroe Software. All rights reserved.
//

import Foundation
import UIKit
import XUCore

extension UIButton {
	public override func localize(from bundle: Bundle = Bundle.main) {
		if let title = self.title(for: .normal) {
			self.setTitle(Localized(title, in: bundle), for: .normal)
		}
	}
}

extension UILabel {
	public override func localize(from bundle: Bundle = Bundle.main) {
		if let text = self.text {
			self.text = Localized(text, in: bundle)
		}
	}
}

extension UITextField {
	public override func localize(from bundle: Bundle = Bundle.main) {
		if let originalPlaceholder = self.attributedPlaceholder {
			let attributes = originalPlaceholder.attributes(at: 0, effectiveRange: nil)
			self.attributedPlaceholder = NSAttributedString(string: Localized(originalPlaceholder.string, in: bundle), attributes: attributes)
		} else {
			// No attributed placeholder
			if let placeholder = self.placeholder {
				self.placeholder = Localized(placeholder, in: bundle)
			}
		}
	}
}

extension UIView: @retroactive XULocalizableUIElement {
		
	@objc public func localize(from bundle: Bundle = Bundle.main) {
		for view in self.subviews {
			view.localize(from: bundle)
		}
	}
}
