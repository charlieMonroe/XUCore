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
	
	public struct Action {
		public let name: String
		public let action: () -> Void
		
		public init(name: String, action: @escaping () -> Void) {
			self.name = name
			self.action = action
		}
		
	}
	
	private class ActionButton: NSButton {
		var popoverAction: Action?
	}
	
	public enum Text {
		case plain(String)
		case attributed(NSAttributedString)
	}
	
	/// Popovers displayed.
	private static var _displayedPopovers: [XUTextPopover] = []
	
	
	/// Popover backing.
	let _popover: NSPopover = NSPopover()
	
	/// Optional action. If not empty, buttons will be displayed below the text.
	public var actions: [Action] = []
	
	/// Padding of the text field in the popover.
	public var padding: CGFloat = 20.0
	
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
	
	@objc private func _performAction(_ sender: ActionButton) {
		sender.popoverAction?.action()
	}
	
	public convenience init(text: String, from view: NSView, relativeTo rect: CGRect? = nil, preferredEdge: NSRectEdge = .minY) {
		self.init(text: .plain(text), from: view, relativeTo: rect, preferredEdge: preferredEdge)
	}
	
	public init(text: Text, from view: NSView, relativeTo rect: CGRect? = nil, preferredEdge: NSRectEdge = .minY) {
		self.preferredEdge = preferredEdge
		self.relativeRect = rect ?? view.bounds
		self.text = text
		self.view = view
		
		super.init()
		
		_popover.behavior = .transient
		_popover.delegate = self
	}
	
	public func popoverDidClose(_ notification: Notification) {
		if let index = XUTextPopover._displayedPopovers.firstIndex(of: self) {
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
		if self.actions.isEmpty {
			view.addConstraints(pinningViewOnAllSides: textField, leftPadding: self.padding, rightPadding: self.padding, topPadding: self.padding, bottomPadding: self.padding)
		} else {
			view.addConstraints(pinningViewHorizontally: textField, leftPadding: self.padding, rightPadding: self.padding)
			view.addConstraint(NSLayoutConstraint(equalAttribute: .top, between: view, and: textField, offset: -self.padding))
			
			var previousView: NSView = textField
			
			for (index, action) in self.actions.enumerated() {
				let button = ActionButton(title: action.name, target: self, action: #selector(_performAction))
				button.popoverAction = action
				button.translatesAutoresizingMaskIntoConstraints = false
				
				if index == 0 {
					button.keyEquivalent = "\n"
					button.isHighlighted = true
				}
				
				view.addSubview(button)
				
				view.addConstraints(pinningViewHorizontally: button, leftPadding: self.padding, rightPadding: self.padding)
				view.addConstraint(
					NSLayoutConstraint(item: button, attribute: .top, relatedBy: .equal, toItem: previousView, attribute: .bottom, multiplier: 1.0, constant: index == 0 ? 16.0 : 8.0)
				)
				
				previousView = button
			}
			
			view.addConstraint(NSLayoutConstraint(equalAttribute: .bottom, between: view, and: previousView, offset: self.padding))
		}
		
		textField.addConstraints([
			NSLayoutConstraint(item: textField, attribute: .width, relatedBy: .lessThanOrEqual, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: self.preferredWidth)
		])
		
		viewController.view = view

		_popover.contentViewController = viewController
		_popover.show(relativeTo: self.relativeRect, of: self.view, preferredEdge: self.preferredEdge)
		
		XUTextPopover._displayedPopovers.append(self)
	}
	
}

