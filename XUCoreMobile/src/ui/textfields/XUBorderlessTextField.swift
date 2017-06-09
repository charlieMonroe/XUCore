//
//  XUBorderlessTextField.swift
//  XUCore
//
//  Created by Charlie Monroe on 6/6/17.
//  Copyright © 2017 Charlie Monroe Software. All rights reserved.
//

import UIKit

/// A borderless text field. Automatically moves the placeholder to the top and
/// makes it font smaller. Similar to how Android text fields work.
@IBDesignable public class XUBorderlessTextField: UITextField {
	
	/// Displays character counter, if maxium character length is non-zero.
	@IBInspectable public var displayCharacterCounter: Bool = true {
		didSet {
			self.invalidateIntrinsicContentSize()
		}
	}
	
	/// Color of the character counter.
	@IBInspectable public var characterCounterTextColor: UIColor = UIColor.darkGray
	
	/// Color of the line.
	@IBInspectable public var lineColor: UIColor {
		get {
			return _lineView.lineColor
		}
		set {
			_lineView.lineColor = newValue
		}
	}
	
	/// The maximum number of characters that the text field allows to be entered.
	/// By character, we assume actual characters. If this value is set to non-zero
	/// value, the counter is displayed in the bottom-right corner (unless disabled).
	@IBInspectable public var maximumCharacterCount: Int = 0 {
		didSet {
			self.invalidateIntrinsicContentSize()
		}
	}
	
	/// Padding of the placeholder from the left of the control.
	@IBInspectable public var placeholderLeftPadding: CGFloat = 15.0
	
	/// Color of the placeholder text.
	@IBInspectable public var placeholderTextColor: UIColor = UIColor.lightGray
	
	
	/// Basic height of the field.
	private let _basicTextFieldHeight: CGFloat = 34.0
	
	/// How much space is reserved for the character counter.
	private let _characterCounterBottomPadding: CGFloat = 20.0
	
	/// Label that displays the character counter.
	private let _characterCounterLabel: UILabel = UILabel()
	
	/// The line under the editing area.
	private let _lineView: XULineView = XULineView()
	
	/// Label that displays the placeholder.
	private let _placeholderLabel: UILabel = UILabel()
	
	
	private func _reloadPlaceholder() {
		_placeholderLabel.font = self.placeholderFont
		_placeholderLabel.textColor = self.placeholderTextColor
		
		if let placeholder = super.placeholder {
			_placeholderLabel.text = XULocalizedString(placeholder)
		}
		
		_placeholderLabel.sizeToFit()
		
		self.addSubview(_placeholderLabel)
		
		// Need to call super since we override the placeholder method to
		// update the label.
		super.placeholder = nil
	}
	
	/// Actually performs layout after the text was changed. Called from
	/// _textDidChange(allowAnimation:).
	private func _layoutAfterTextDidChange() {
		self._placeholderLabel.font = self.placeholderFont
		self._placeholderLabel.sizeToFit()
		
		self.layoutSubviews()
	}
	
	/// Lays out the placeholder label.
	private func _layoutPlaceholderLabel() {
		_placeholderLabel.sizeToFit()
		var placeholderFrame = _placeholderLabel.frame
		placeholderFrame.origin.x = self.textRect(forBounds: self.bounds).minX
		
		var basicFrame = self.bounds
		if self.isCharacterCounterDisplayed {
			basicFrame.origin.y = _characterCounterBottomPadding
			basicFrame.size.height -= _characterCounterBottomPadding
		}
		
		if self.isEmpty {
			placeholderFrame.origin.y = basicFrame.height - placeholderFrame.height - 1.0
		} else {
			placeholderFrame.origin.y = 0.0
		}
		placeholderFrame.size.width = self.bounds.width - (2.0 * placeholderFrame.minX)
		_placeholderLabel.frame = placeholderFrame
	}
	
	private func _textDidChange(allowAnimation: Bool) {
		if self.window != nil, allowAnimation {
			UIView.animate(withDuration: 0.15, animations: {
				self._layoutAfterTextDidChange()
			})
		} else {
			self._layoutAfterTextDidChange()
		}
	}
	
	@objc private func _textDidChangeNotification() {
		if self.maximumCharacterCount != 0 {
			if let text = self.text, text.characters.count > self.maximumCharacterCount {
				self.text = text.substring(to: text.index(text.startIndex, offsetBy: self.maximumCharacterCount))
				_characterCounterLabel.animation.wobble()
			}
		}
		
		self._updateCharacterCount()
		self._textDidChange(allowAnimation: true)
	}
	
	private func _updateCharacterCount() {
		if self.isCharacterCounterDisplayed {
			_characterCounterLabel.text = "\(self.text?.characters.count ?? 0)/\(self.maximumCharacterCount)"
		}
	}
	
	/// See awakeFromNib().
	public override func awakeFromNib() {
		super.awakeFromNib()
		
		self.borderStyle = .none
		
		NotificationCenter.default.addObserver(self, selector: #selector(_textDidChangeNotification), name: NSNotification.Name.UITextFieldTextDidChange, object: self)
		
		_lineView.lineWidth = 1.0
		self.addSubview(_lineView)
		
		self._updateCharacterCount()
		
		_characterCounterLabel.textColor = self.characterCounterTextColor
		_characterCounterLabel.font = UIFont.systemFont(ofSize: 11.0)
		self.addSubview(_characterCounterLabel)
		
		self._reloadPlaceholder()
	}
	
	/// See UIResponder.
	@discardableResult
	public override func becomeFirstResponder() -> Bool {
		guard super.becomeFirstResponder() else {
			return false
		}
		
		_lineView.lineWidth = 1.5
		return true
	}
	
	/// See UIView.
	public override func draw(_ rect: CGRect) {
		super.draw(rect)
		
		// Draw placeholder anyway
		self.drawPlaceholder(in: rect)
	}
	
	/// See UITextField.
	public override func drawPlaceholder(in rect: CGRect) {
		
	}
	
	/// See UITextField.
	public override func editingRect(forBounds bounds: CGRect) -> CGRect {
		return self.textRect(forBounds: bounds)
	}
	
	public override var intrinsicContentSize: CGSize {
		var size = super.intrinsicContentSize
		size.height = _basicTextFieldHeight
		if self.isCharacterCounterDisplayed {
			size.height += _characterCounterBottomPadding
		}
		return size
	}
	
	/// Indicates if the character counter is displayed.
	public var isCharacterCounterDisplayed: Bool {
		return self.displayCharacterCounter && self.maximumCharacterCount > 0
	}
	
	/// See UIView.
	public override func layoutSubviews() {
		super.layoutSubviews()
		
		self._layoutPlaceholderLabel()
		
		let lineFrame = CGRect(x: 0.0, y: _basicTextFieldHeight, width: self.bounds.width, height: 2.0)
		_lineView.frame = lineFrame
		
		if self.isCharacterCounterDisplayed {
			_characterCounterLabel.isHidden = false
			_characterCounterLabel.sizeToFit()
			
			var characterCounterFrame = _characterCounterLabel.frame
			characterCounterFrame.origin.x = self.bounds.width - characterCounterFrame.width
			characterCounterFrame.origin.y = _basicTextFieldHeight + 4.0
			_characterCounterLabel.frame = characterCounterFrame
		} else {
			_characterCounterLabel.isHidden = true
		}
	}
	
	/// See UITextField.
	public override var placeholder: String? {
		didSet {
			self._reloadPlaceholder()
		}
	}
	
	/// Returns the font currently used for the placeholder.
	var placeholderFont: UIFont {
		let font: UIFont
		if self.isEmpty {
			font = self.font!
		} else {
			font = self.font!.withSize(11.0)
		}
		return font
	}
	
	/// See UIResponder.
	public override func resignFirstResponder() -> Bool {
		guard super.resignFirstResponder() else {
			return false
		}
		
		_lineView.lineWidth = 1.0
		return true
	}
	
	/// See UITextField.
	public override func textRect(forBounds originalBounds: CGRect) -> CGRect {
		var bounds = originalBounds
		if self.isCharacterCounterDisplayed {
			bounds.size.height -= _characterCounterBottomPadding
		}
		
		var textRect = super.textRect(forBounds: bounds)
		textRect.origin.y += 8.0
		return textRect
	}
	
	/// See UITextField.
	public override var text: String? {
		didSet {
			self._textDidChange(allowAnimation: false)
			self._updateCharacterCount()
		}
	}
		
}
