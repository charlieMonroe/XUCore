//
//  XUPickerViewControllers.swift
//  XUCoreMobile
//
//  Created by Charlie Monroe on 3/28/18.
//  Copyright © 2018 Charlie Monroe Software. All rights reserved.
//

import UIKit

public protocol XUPickerControl: AnyObject {
	
	/// Associtated type.
	associatedtype Item
	
	/// Returns selected item.
	var selectedItem: Item? { get set }
	
}

/// A base class that displays a picker inside a controller. We need a base class
/// so that we can easily support both generic picker and date picker.
public class XUPickerBaseViewController<Item, ItemControl: UIControl & XUPickerControl>: UIViewController where ItemControl.Item == Item {
	
	/// Background control that handles dismissal.
	@IBOutlet private weak var _backgroundControl: UIControl!
	
	/// Picker.
	private let _picker: ItemControl
	
	/// View encapsulating the picker.
	@IBOutlet private weak var _pickerEnclosingView: UIView!
	
	/// Layout constraint that's pinning down the picker's enclosing view.
	var _pickerEnclosingViewBottomLayoutConstraint: NSLayoutConstraint!
	
	/// Completion handler set in show(with:).
	private var _completionHandler: ((Item?) -> Void)?
	
	/// Parent controller in which the content should be displayer.
	public let parentController: UIViewController
	
	
	
	
	/// An action from _backgroundControl that causes cancellation.
	@IBAction private func _cancel(_ sender: Any?) {
		self._dismiss(with: nil)
	}
	
	private func _dismiss(with item: Item?) {
		// Animation of dismissal.
		UIView.animate(withDuration: 0.3, animations: {
			self._backgroundControl.alpha = 0.0
			self._pickerEnclosingViewBottomLayoutConstraint.constant = self._pickerEnclosingView.frame.height
			self.view.layoutSubviews()
		}) { (_) in
			self.removeFromParentViewController()
			self.view.removeFromSuperview()
			
			self._completionHandler?(item)
			self._completionHandler = nil
		}
	}
	
	/// An action from the Done button.
	@IBAction private func _done(_ sender: Any?) {
		self._dismiss(with: _picker.selectedItem)
	}
	
	/// Designated initializer.
	public init(parentController: UIViewController, selectedItem: Item? = nil) {
		self.parentController = parentController
		_picker = ItemControl()
		
		super.init(nibName: "XUPickerViewController", bundle: XUCoreFramework.bundle)
		
		self.view.backgroundColor = .clear
		
		_picker.translatesAutoresizingMaskIntoConstraints = false
		_pickerEnclosingView.addSubview(_picker)
		
		_pickerEnclosingView.addConstraints(pinningViewHorizontally: _picker)
		
		let bottomConstraint = NSLayoutConstraint(item: _picker, attribute: .bottom, relatedBy: .equal, toItem: _pickerEnclosingView, attribute: .bottom, multiplier: 1.0, constant: 0.0)
		_pickerEnclosingView.addConstraint(bottomConstraint)
		_pickerEnclosingViewBottomLayoutConstraint = bottomConstraint
		
		_picker.addConstraint(NSLayoutConstraint(item: _picker, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 216.0))
		
		_picker.selectedItem = selectedItem
	}
	
	/// Displays the picker with a completion handler.
	public func show(with completionHandler: @escaping (Item?) -> Void) {
		assert(_completionHandler == nil)
		
		_completionHandler = completionHandler
		
		_backgroundControl.alpha = 0.0
		_pickerEnclosingViewBottomLayoutConstraint.constant = _pickerEnclosingView.frame.height
		
		self.view.layoutSubviews()
		self.view.translatesAutoresizingMaskIntoConstraints = false
		
		self.parentController.view.window!.addSubview(self.view)
		self.parentController.view.window!.addConstraints(pinningViewOnAllSides: self.view)
		
		UIView.animate(withDuration: 0.3) {
			self._backgroundControl.alpha = 1.0
			self._pickerEnclosingViewBottomLayoutConstraint.constant = 0.0
			self.view.layoutSubviews()
		}
	}
	
	
	@available(*, unavailable)
	public required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
}

extension UIDatePicker: XUPickerControl {
	
	public var selectedItem: Date? {
		get {
			return self.date
		}
		set {
			guard let date = newValue else {
				self.date = Date()
				return
			}
			
			self.date = date
		}
	}
	
}

public class XUDatePickerViewController: XUPickerBaseViewController<Date, UIDatePicker> {
}


