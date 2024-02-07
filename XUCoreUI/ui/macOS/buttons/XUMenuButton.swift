//
//  XUMenuButton.swift
//  XUCore
//
//  Created by Charlie Monroe on 11/5/15.
//  Copyright © 2015 Charlie Monroe Software. All rights reserved.
//

import AppKit

/// Alignment of the menu towards to the button.
@objc public enum XUMenuAlignment: Int {
	/// The menu is aligned with the right edge.
	case rightEdge = 0
	
	/// The menu is aligned with the left edge.
	case leftEdge = 1
}

/// This is a button that displays self.menu on click as well as on rightMouseDown
/// - positioned correctly.
open class XUMenuButton: NSButton {

	/// Menu alignment.
	@IBInspectable public var menuAlignment: XUMenuAlignment = .rightEdge
	
	/// Font used for the menu.
	@IBInspectable public var menuFont: NSFont? {
		didSet {
			self._updateMenuFont()
		}
	}
	
	/// Offset for displaying the menu. You can offset it to pixel-perfectly align
	/// it with the text/image.
	@IBInspectable public var menuOffset: CGSize = CGSize()
	
	@objc private func _displayMenu() {
		guard let menu = self.menu else {
			return
		}
		
		var point = CGPoint(x: 0.0 + self.menuOffset.width, y: self.bounds.height + self.menuOffset.height)
		switch self.menuAlignment {
		case .leftEdge:
			// It's fine like that
			break
		case .rightEdge:
			let size = menu.size
			point.x += self.bounds.width
			point.x -= size.width
		}
		
		menu.popUp(positioning: nil, at: point, in: self)
	}
	
	private func _updateMenuFont() {
		let font: NSFont
		if let f = self.menuFont {
			font = f
		} else {
			// Base this on control size.
			let size = NSFont.systemFontSize(for: self.controlSize)
			font = NSFont.systemFont(ofSize: size)
		}
		
		self.menu?.font = font
	}
	
	open override func awakeFromNib() {
		self.target = self
		self.action = #selector(XUMenuButton._displayMenu)
		
		self.menu?.localize()
		self._updateMenuFont()
		
		super.awakeFromNib()
	}
	open override func rightMouseDown(with event: NSEvent) {
		self._displayMenu()
	}
    
}
