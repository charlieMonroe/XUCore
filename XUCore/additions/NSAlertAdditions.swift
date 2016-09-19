//
//  NSAlertAdditions.swift
//  XUCore
//
//  Created by Charlie Monroe on 11/20/15.
//  Copyright © 2015 Charlie Monroe Software. All rights reserved.
//

import Foundation

public extension NSAlert {
	
	fileprivate func _isDefaultButton(_ response: NSModalResponse) -> Bool {
		if self.buttons.count == 0 {
			return true // The alert only has one default OK button
		}
		
		if self.buttons.first!.tag == NSAlertFirstButtonReturn {
			return response == NSAlertFirstButtonReturn
		}
		
		NSException(name: NSExceptionName.internalInconsistencyException, reason: "Running a deprecated NSAlert instance!", userInfo: nil).raise()
		abort()
	}
	
	fileprivate func _prepareAccessoryTextFieldWithInitialValue(_ initialValue: String, secure: Bool) {
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
		self.addButton(withTitle: XULocalizedString("Cancel", inBundle: XUCore.bundle))
	}
	
	/// Adds a button with title "OK".
	public func addOKButton() {
		self.addButton(withTitle: XULocalizedString("OK", inBundle: XUCore.bundle))
	}
	
	/// Begins the alert as sheet from window with a text field as accessory view,
	/// containing initialValue. If secure is true, the text field is secure.
	public func beginSheetModal(withTextField initialValue: String, secure: Bool = false, forWindow window: NSWindow, completionHandler handler: @escaping (NSModalResponse, String?) -> Void) {

		self._prepareAccessoryTextFieldWithInitialValue(initialValue, secure: secure)
		self.beginSheetModal(for: window, completionHandler: { (response) in
			if response == NSAlertFirstButtonReturn {
				handler(response, (self.accessoryView as! NSTextField).stringValue)
			} else {
				handler(response, nil)
			}
		})
		
		// Make sure the field's focused
		if let accessory = self.accessoryView {
			accessory.window?.makeFirstResponder(accessory)
		}
	}
	
	/// Create a pop up button as its own accessory view in the alert and populates
	/// it with menuItems.
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
		self._prepareAccessoryTextFieldWithInitialValue(initialValue, secure: secure)
		
		if !self._isDefaultButton(self.runModalOnMainThread()) {
			return nil // Cancelled
		}
		
		return (self.accessoryView as! NSTextField).stringValue
	}
	
}

public extension NSAlert {
	
	@available(*, deprecated, renamed: "runModal(withTextField:secure:)")
	public func runModalWithTextFieldOnMainThread(_ initialValue: String, secure: Bool = false) -> String? {
		return self.runModal(withTextField: initialValue, secure: secure)
	}
}

