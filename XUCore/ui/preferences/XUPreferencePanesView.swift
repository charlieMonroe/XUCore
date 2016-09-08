//
//  XUPreferencePanesView.swift
//  XUCore
//
//  Created by Charlie Monroe on 9/5/16.
//  Copyright © 2016 Charlie Monroe Software. All rights reserved.
//

import Cocoa

/// Delegate for the view.
internal protocol XUPreferencePanesViewDelegate: AnyObject {
	func preferencePaneView(didSelectPane paneController: XUPreferencePaneViewController)
}

/// This class will display the sections and preference panes. This class is
/// currently internal, but it may become public in the future to allow customization.
internal class XUPreferencePanesView: NSView {

	/// Width between the buttons.
	fileprivate static let buttonPadding: CGFloat = 16.0

	/// Width of the buttons.
	fileprivate static let buttonWidth: CGFloat = 78.0

	/// Size of the icon.
	fileprivate static let iconSize: CGFloat = 32.0

	/// Height of each section.
	fileprivate static let sectionHeight: CGFloat = 92.0

	/// Attributes of the title.
	fileprivate static let titleAttributes: [String: AnyObject] = [
		NSForegroundColorAttributeName: NSColor.textColor,
		NSFontAttributeName: XUPreferencePanesView.titleFont
	]

	/// Font used for button titles.
	fileprivate static let titleFont: NSFont = NSFont.systemFont(ofSize: 12.0)

	/// Width of the window. This is always the same.
	internal static let viewWidth: CGFloat = 660.0

	/// Buttons.
	fileprivate let _buttons: [[XUPreferencePaneButton]]

	/// Cached heights of the sections.
	fileprivate let _sectionHeights: [CGFloat]

	/// Delegate.
	weak var delegate: XUPreferencePanesViewDelegate!

	/// Sections.
	let sections: [XUPreferencePanesSection]

	@objc fileprivate func _didSelectPane(_ paneButton: XUPreferencePaneButton) {
		self.delegate.preferencePaneView(didSelectPane: paneButton.paneController)
	}

	override func draw(_ dirtyRect: CGRect) {
		var y: CGFloat = 0.0
		for (index, height) in _sectionHeights.enumerated() {
			if index % 2 != 0 {
				NSColor(white: 0.8667, alpha: 1.0).set()
				NSBezierPath(rect: CGRect(x: 0.0, y: y, width: XUPreferencePanesView.viewWidth, height: height)).fill()
			}

			y += height

			if index == _sectionHeights.count - 1 {
				break
			}

			NSColor(white: 0.0, alpha: 0.2).set()
			NSBezierPath(rect: CGRect(x: 0.0, y: y - 1.0, width: XUPreferencePanesView.viewWidth, height: 1.0)).fill()
		}
	}

	override var isFlipped: Bool {
		return true
	}

	init(sections: [XUPreferencePanesSection], andDelegate delegate: XUPreferencePanesViewDelegate) {
		var frame: CGRect = CGRect(x: 0.0, y: 0.0, width: XUPreferencePanesView.viewWidth, height: XUPreferencePanesView.sectionHeight * CGFloat(sections.count))

		var buttons: [[XUPreferencePaneButton]] = sections.map({ _ in [] })
		var sectionHeights: [CGFloat] = sections.map({ _ in XUPreferencePanesView.sectionHeight })

		// Unfortunately, this isn't as easy as it sounds since we need to make
		// sure that all sections fit within one row.
		for (sectionIndex, section) in sections.enumerated() {
			var x: CGFloat = XUPreferencePanesView.buttonPadding
			for pane in section.paneControllers {
				x += XUPreferencePanesView.buttonWidth + XUPreferencePanesView.buttonPadding
				if x + XUPreferencePanesView.buttonPadding > XUPreferencePanesView.viewWidth {
					frame.size.height += XUPreferencePanesView.sectionHeight
					sectionHeights[sectionIndex] += XUPreferencePanesView.sectionHeight

					x = XUPreferencePanesView.buttonPadding
				}

				buttons[sectionIndex].append(XUPreferencePaneButton(paneController: pane))
			}
		}

		_buttons = buttons
		_sectionHeights = sectionHeights

		self.delegate = delegate
		self.sections = sections

		super.init(frame: frame)

		for button in buttons.joined() {
			self.addSubview(button)
			button.target = self
			button.action = #selector(_didSelectPane(_:))
		}
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	override func layout() {
		super.layout()

		var y: CGFloat = XUPreferencePanesView.sectionHeight
		for (sectionIndex, section) in sections.enumerated() {
			var x: CGFloat = XUPreferencePanesView.buttonPadding
			for (paneIndex, _) in section.paneControllers.enumerated() {
				let button = _buttons[sectionIndex][paneIndex]
				var size = button.sizeThatFits(CGSize(width: XUPreferencePanesView.buttonWidth, height: XUPreferencePanesView.sectionHeight))
				if button.paneController.paneName.range(of: " ") != nil {
					size.width = min(size.width, XUPreferencePanesView.buttonWidth)
				}

				button.frame = CGRect(x: x + (XUPreferencePanesView.buttonWidth - size.width) / 2.0, y: y - XUPreferencePanesView.sectionHeight + 16.0, width: size.width, height: size.height).integral

				x += XUPreferencePanesView.buttonWidth + XUPreferencePanesView.buttonPadding
				if x + XUPreferencePanesView.buttonPadding > XUPreferencePanesView.viewWidth {
					x = XUPreferencePanesView.buttonPadding
					y += XUPreferencePanesView.sectionHeight
				}
			}

			y += XUPreferencePanesView.sectionHeight
		}
	}

}

private class XUPreferencePaneButtonCell: NSButtonCell {
	
	override func drawTitle(_ title: NSAttributedString, withFrame frame: CGRect, in controlView: NSView) -> CGRect {
		let attributedString = NSAttributedString(string: title.string.replacingOccurrences(of: " ", with: "\n"))
		
		let paragraphStyle = NSParagraphStyle.default().mutableCopy() as! NSMutableParagraphStyle
		paragraphStyle.alignment = .center

		let attributes = [
			NSFontAttributeName: XUPreferencePanesView.titleFont,
			NSParagraphStyleAttributeName: paragraphStyle
		]

		let textSize = attributedString.string.size(withAttributes: attributes)
		let textBounds = CGRect(x: 0.0, y: 0.0, width: textSize.width, height: textSize.height)

		let textFrame = CGRect(x: 0.0, y: 34.0, width: controlView.frame.width, height: textSize.height)
		attributedString.string.draw(in: textFrame, withAttributes: attributes)
		
		return textBounds
	}

}

private class XUPreferencePaneButton: NSButton {

	override class func cellClass() -> AnyClass? {
		return XUPreferencePaneButtonCell.self
	}
	
	let paneController: XUPreferencePaneViewController

	init(paneController: XUPreferencePaneViewController) {
		self.paneController = paneController

		super.init(frame: CGRect())

		self.translatesAutoresizingMaskIntoConstraints = false
		self.title = paneController.paneName
		self.image = paneController.paneIcon
		self.imagePosition = .imageAbove
		self.font = XUPreferencePanesView.titleFont
		self.isBordered = false
		self.setButtonType(.momentaryChange)
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	fileprivate override func sizeThatFits(_ size: CGSize) -> CGSize {
		let attributedString = NSAttributedString(string: self.title.replacingOccurrences(of: " ", with: "\n"))
		
		let paragraphStyle = NSParagraphStyle.default().mutableCopy() as! NSMutableParagraphStyle
		paragraphStyle.alignment = .center
		
		let attributes = [
			NSFontAttributeName: XUPreferencePanesView.titleFont,
			NSParagraphStyleAttributeName: paragraphStyle
		]
		
		let textSize = attributedString.string.size(withAttributes: attributes)
		var result = textSize
		result.height = 32.0 + textSize.height + 2.0
		return result
	}

}
