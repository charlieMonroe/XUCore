//
//  XUTextPopover.swift
//  XUCore
//
//  Created by Charlie Monroe on 2/23/18.
//  Copyright © 2018 Charlie Monroe Software. All rights reserved.
//

import AppKit

/// Creates a popover with a text and allows you to display it from a NSView.
/// It automatically handles memory management and keeps itself alive for as long
/// as needed.
final public class XUTextPopover: NSObject, NSPopoverDelegate {
	
	public enum Text {
		case plain(String)
		case attributed(NSAttributedString)
	}
	
	/// Popovers displayed.
	private static var _displayedPopovers: [XUTextPopover] = []
	
	
	/// Popover backing.
	let _popover: NSPopover = NSPopover()
	
	
	/// Padding of the text field in the popover.
	public var padding: CGFloat = 10.0
	
	/// Preferred edge of the view.
	public let preferredEdge: NSRectEdge
	
	/// Preferred width of the text field.
	public var preferredWidth: CGFloat = 300.0
	
	/// Rect relative to the view.
	public let relativeRect: CGRect
	
	/// Text being displayed.
	public let text: Text
	
	/// Text alignment.
	public var textAlignment: NSTextAlignment = .natural
	
	/// Font of the text. Small system font by default.
	public var textFont: NSFont = NSFont.systemFont(ofSize: NSFont.smallSystemFontSize)
	
	/// View.
	public let view: NSView
	
	
	public convenience init(text: String, from view: NSView, relativeTo rect: CGRect, preferredEdge: NSRectEdge) {
		self.init(text: .plain(text), from: view, relativeTo: rect, preferredEdge: preferredEdge)
	}
	
	public init(text: Text, from view: NSView, relativeTo rect: CGRect, preferredEdge: NSRectEdge) {
		self.preferredEdge = preferredEdge
		self.relativeRect = rect
		self.text = text
		self.view = view
		
		super.init()
		
		_popover.behavior = .transient
		_popover.delegate = self
	}
	
	public func popoverDidClose(_ notification: Notification) {
		if let index = XUTextPopover._displayedPopovers.index(of: self) {
			XUTextPopover._displayedPopovers.remove(at: index)
		}
	}
	
	public func show() {
		let viewController = NSViewController()
		
		let view = NSView()
		
		let textField = NSTextField()
		textField.drawsBackground = false
		textField.isBordered = false
		textField.isEditable = false
		textField.isSelectable = false
		
		textField.font = self.textFont
		textField.alignment = self.textAlignment
		
		switch self.text {
		case .plain(let plain):
			textField.stringValue = plain
		case .attributed(let attributed):
			textField.attributedStringValue = attributed
		}
		
		textField.translatesAutoresizingMaskIntoConstraints = false
		
		view.addSubview(textField)
		view.addConstraints(pinningViewOnAllSides: textField, leftPadding: 20.0, rightPadding: 20.0, topPadding: 20.0, bottomPadding: 20.0)
		textField.addConstraints([
			NSLayoutConstraint(item: textField, attribute: .width, relatedBy: .lessThanOrEqual, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: self.preferredWidth)
		])
		
		viewController.view = view

		_popover.contentViewController = viewController
		_popover.show(relativeTo: self.relativeRect, of: self.view, preferredEdge: self.preferredEdge)
		
		XUTextPopover._displayedPopovers.append(self)
	}
	
}

