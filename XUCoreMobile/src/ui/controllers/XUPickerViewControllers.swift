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
	var selectedItem: Item { get set }
	
}

/// A base class that displays a picker inside a controller. We need a base class
/// so that we can easily support both generic picker and date picker.
public class XUPickerBaseViewController<Item, ItemControl: UIView & XUPickerControl>: UIViewController where ItemControl.Item == Item {
	
	/// Background control that handles dismissal.
	@IBOutlet private weak var _backgroundControl: UIControl!
	
	/// View encapsulating the picker.
	@IBOutlet private weak var _pickerEnclosingView: UIView!
	
	/// Layout constraint that's pinning down the picker's enclosing view.
	var _pickerEnclosingViewBottomLayoutConstraint: NSLayoutConstraint!
	
	/// Completion handler set in show(with:).
	private var _completionHandler: ((Item?) -> Void)?
	
	
	
	/// Parent controller in which the content should be displayer.
	public let parentController: UIViewController
	
	/// Picker.
	public let picker: ItemControl
	
	
	
	/// An action from _backgroundControl that causes cancellation.
	@IBAction private func _cancel(_ sender: Any?) {
		self._dismiss(with: nil)
	}
	
	private func _dismiss(with item: Item?) {
		// Animation of dismissal.
		UIView.animate(withDuration: 0.3, animations: {
			self._backgroundControl.alpha = 0.0
			self._pickerEnclosingView.frame.origin.y += self._pickerEnclosingView.frame.height
		}) { (_) in
			self.removeFromParent()
			self.view.removeFromSuperview()
			
			self._completionHandler?(item)
			self._completionHandler = nil
		}
	}
	
	/// An action from the Done button.
	@IBAction private func _done(_ sender: Any?) {
		self._dismiss(with: picker.selectedItem)
	}
	
	/// Designated initializer.
	public init(parentController: UIViewController, selectedItem: Item) {
		self.parentController = parentController
		picker = ItemControl()
		
		super.init(nibName: "XUPickerViewController", bundle: XUCoreFramework.bundle)
		
		self.view.backgroundColor = .clear
		
		picker.translatesAutoresizingMaskIntoConstraints = false
		_pickerEnclosingView.addSubview(picker)
		
		_pickerEnclosingView.addConstraints(pinningViewHorizontally: picker)
		
		let bottomConstraint = NSLayoutConstraint(item: picker, attribute: .bottom, relatedBy: .equal, toItem: _pickerEnclosingView, attribute: .bottom, multiplier: 1.0, constant: 0.0)
		_pickerEnclosingView.addConstraint(bottomConstraint)
		_pickerEnclosingViewBottomLayoutConstraint = bottomConstraint
		
		picker.addConstraint(NSLayoutConstraint(item: picker, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 216.0))
		
		picker.selectedItem = selectedItem
	}
	
	/// Displays the picker with a completion handler.
	public func show(with completionHandler: @escaping (Item?) -> Void) {
		assert(_completionHandler == nil)
		
		_completionHandler = completionHandler
		
		self.view.layoutSubviews()
		
		_backgroundControl.alpha = 0.0
		_pickerEnclosingView.frame.origin.y += _pickerEnclosingView.frame.height
		
		self.view.translatesAutoresizingMaskIntoConstraints = false
		
		self.parentController.view.window!.addSubview(self.view)
		self.parentController.view.window!.addConstraints(pinningViewOnAllSides: self.view)
		
		UIView.animate(withDuration: 0.3) { [unowned self] in
			self._backgroundControl.alpha = 1.0
			self._pickerEnclosingView.frame.origin.y -= self._pickerEnclosingView.frame.height
		}
	}
	
	
	@available(*, unavailable)
	public required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
}

extension UIDatePicker: XUPickerControl {
	
	public var selectedItem: Date {
		get {
			return self.date
		}
		set {
			self.date = newValue
		}
	}
	
}

extension UIPickerView: XUPickerControl {
	
	public var selectedItem: Int {
		get {
			return self.selectedRow(inComponent: 0)
		}
		set {
			self.selectRow(newValue, inComponent: 0, animated: true)
		}
	}
	
}

/// A date picker controller. It will slide from the bottom of the screen like a keyboard
/// and will allow you to select a date.
public class XUDatePickerViewController: XUPickerBaseViewController<Date, UIDatePicker> {
}

/// A generic picker controller. It will slide from the bottom of the screen like a keyboard
/// and will allow you to select one of the options.
public class XUPickerViewController<T: Equatable>: XUPickerBaseViewController<Int, UIPickerView>, UIPickerViewDataSource, UIPickerViewDelegate {
	
	/// Data item to be displayed in the picker.
	public struct DataItem: Equatable {
		
		public static func ==(lhs: DataItem, rhs: DataItem) -> Bool {
			return lhs.title == rhs.title && lhs.value == rhs.value
		}
		
		/// Title of the item.
		public let title: String
		
		/// Value of the item.
		public let value: T
		
		public init(title: String, value: T) {
			self.title = title
			self.value = value
		}
	}
	
	/// Items.
	public let items: [DataItem]
	
	public init(parentController: UIViewController, items: [DataItem], selectedItem: DataItem) {
		guard !items.isEmpty, let index = items.index(of: selectedItem) else {
			XUFatalError("Items are either empty or the selected item is not among them.")
		}
		
		self.items = items
		
		super.init(parentController: parentController, selectedItem: index)
		
		self.picker.dataSource = self
		self.picker.delegate = self
	}
	
	public func numberOfComponents(in pickerView: UIPickerView) -> Int {
		return 1
	}
	
	public func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
		return self.items.count
	}
	
	public func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
		return self.items[row].title
	}
	
	/// Convenience method that passes the selected data item instead of the index.
	public func show(with completionHandler: @escaping (DataItem?) -> Void) {
		let items = self.items
		self.show { (index: Int?) in
			guard let index = index else {
				completionHandler(nil)
				return
			}
			
			completionHandler(items[index])
		}
	}
	
}

