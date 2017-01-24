//
//  NSAlertAdditions.swift
//  XUCore
//
//  Created by Charlie Monroe on 11/20/15.
//  Copyright © 2015 Charlie Monroe Software. All rights reserved.
//

import Foundation

public extension NSAlert {
	
	/// This enum contains the payload used by beginSheetModal(withTextField:...).
	public enum StringModalResponse {
		
		/// The alert was cancelled - or to be precise a button was pressed that
		/// is not the first button.
		case cancelled(NSModalResponse)
		
		/// The alert was confirmed using the first button and String was entered.
		case confirmed(String, NSModalResponse)
		
		
		/// Returns true if the value of the enum is cancelled(_).
		public var isCancelled: Bool {
			switch self {
			case .cancelled(_):
				return true
			case .confirmed(_, _):
				return false
			}
		}
		
		/// Returns true if the value of the enum is confirmed(_).
		public var isConfirmed: Bool {
			return !self.isCancelled
		}
		
		/// Returns the modal response payload.
		public var modalResponse: NSModalResponse {
			switch self {
			case .cancelled(let response):
				return response
			case .confirmed(_, let response):
				return response
			}
		}
		
		/// Returns the payload of .confirmed(_). Will call fatalError if called
		/// on .cancelled(_) value.
		public var stringValue: String {
			switch self {
			case .cancelled(_):
				fatalError("Calling stringValue on StringModalResponse.cancelled(_).")
			case .confirmed(let value, _):
				return value
			}
		}
	}
	
	
	fileprivate func _isDefaultButton(_ response: NSModalResponse) -> Bool {
		if self.buttons.count == 0 {
			return true // The alert only has one default OK button
		}
		
		if self.buttons.first!.tag == NSAlertFirstButtonReturn {
			return response == NSAlertFirstButtonReturn
		}
		
		fatalError("Running a deprecated NSAlert instance!")
	}
	
	fileprivate func _prepareAccessoryTextField(withInitialValue initialValue: String, secure: Bool) {
		let frame = CGRect(x: 0.0, y: 0.0, width: 290.0, height: 22.0)
		let accessory: NSTextField
		if secure {
			accessory = NSSecureTextField(frame: frame)
		} else {
			accessory = NSTextField(frame: frame)
		}
		
		accessory.stringValue = initialValue
		
		self.accessoryView = accessory

		accessory.becomeFirstResponder()
	}
	
	/// Adds a button with title "Cancel".
	public func addCancelButton() {
		self.addButton(withTitle: XULocalizedString("Cancel", inBundle: XUCoreFramework.bundle))
	}
	
	/// Adds a button with title "OK".
	public func addOKButton() {
		self.addButton(withTitle: XULocalizedString("OK", inBundle: XUCoreFramework.bundle))
	}
	
	/// Begins the alert as sheet from window with a text field as accessory view,
	/// containing initialValue. If secure is true, the text field is secure.
	@available(*, deprecated, message: "Use the variant with StringModalResponse instead.")
	public func beginSheetModal(withTextField initialValue: String, secure: Bool = false, forWindow window: NSWindow, completionHandler handler: @escaping (NSModalResponse, String?) -> Void) {
		self.beginSheetModal(withTextField: initialValue, isSecure: secure, forWindow: window, completionHandler: { (response) in
			if response.isCancelled {
				handler(response.modalResponse, nil)
			} else {
				handler(response.modalResponse, response.stringValue)
			}
		})
		
	}
	
	/// Begins the alert as sheet from window with a text field as accessory view,
	/// containing initialValue. If isSecure is true, the text field is secure.
	/// 
	/// The completion handler will be called with one of the values of the 
	/// StringModalResponse enum. The alert is considered as confirmed if the
	/// NSAlertFirstButtonReturn button is pressed.
	public func beginSheetModal(withTextField initialValue: String, isSecure: Bool = false, forWindow window: NSWindow, completionHandler: @escaping (StringModalResponse) -> Void) {
		self._prepareAccessoryTextField(withInitialValue: initialValue, secure: isSecure)
		self.beginSheetModal(for: window, completionHandler: { (response) in
			if response == NSAlertFirstButtonReturn {
				completionHandler(.confirmed((self.accessoryView as! NSTextField).stringValue, response))
			} else {
				completionHandler(.cancelled(response))
			}
		})
		
		// Make sure the field's focused
		if let accessory = self.accessoryView {
			accessory.window?.makeFirstResponder(accessory)
		}
	}
	
	/// Create a pop up button as its own accessory view in the alert and populates
	/// it with menuItems. It returnes the pop up button it created for further
	/// customization.
	@discardableResult
	public func createAccessoryPopUpButton(withMenuItems menuItems: [NSMenuItem]) -> NSPopUpButton {
		let popUpButton = NSPopUpButton(frame: CGRect(x: 0.0, y: 0.0, width: 300.0, height: 22.0), pullsDown: false)
		self.accessoryView = popUpButton
		
		var anyImageTooLargeForInlineDisplay = false
		let menu = NSMenu()
		for item in menuItems {
			if let image = item.image {
				if image.size.height > 16.0 {
					// This image wouldn't fit the pop up button -> we need to allow scaling
					anyImageTooLargeForInlineDisplay = true
				}
			}
			menu.addItem(item)
		}
		
		popUpButton.menu = menu
		
		if anyImageTooLargeForInlineDisplay {
			(popUpButton.cell as? NSPopUpButtonCell)?.imageScaling = .scaleProportionallyDown
		}
		return popUpButton
	}
	
	/// Ensures that the alert is run on main thread. If current thread isn't main,
	/// the thread is blocked until the alert is dismissed.
	@discardableResult
	public func runModalOnMainThread() -> NSModalResponse {
		var result: NSModalResponse = NSAlertFirstButtonReturn
		XU_PERFORM_BLOCK_ON_MAIN_THREAD({ () -> Void in
			result = self.runModal()
		})
		
		return result
	}
	
	/// Runs modal and displays a text field as accessory view. Nil is returned
	/// when the user dismisses the dialog with anything else but
	/// NSAlertFirstButtonReturn. If secure is ture, the text field is secure.
	public func runModal(withTextField initialValue: String, secure: Bool = false) -> String? {
		self._prepareAccessoryTextField(withInitialValue: initialValue, secure: secure)
		
		if !self._isDefaultButton(self.runModalOnMainThread()) {
			return nil // Cancelled
		}
		
		return (self.accessoryView as! NSTextField).stringValue
	}
	
}
