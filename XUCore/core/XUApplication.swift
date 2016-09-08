//
//  XUApplication.swift
//  XUCore
//
//  Created by Charlie Monroe on 11/9/15.
//  Copyright © 2015 Charlie Monroe Software. All rights reserved.
//

import Foundation

@objc public protocol XUArrowKeyEventsObserver: AnyObject {
	
	/// Esc was pressed
	func cancelationKeyWasPressed(_ event: NSEvent)
	
	/// Either enter or return was pressed
	func confirmationKeyWasPressed(_ event: NSEvent)
	
	/// Key down was pressed
	func keyDownWasPressed(_ event: NSEvent)
	
	/// Key up was pressed
	func keyUpWasPressed(_ event: NSEvent)
	
	/// If true, the observer is notified even when the key responder is a text
	/// field or text view.
	var observeEvenWhenEditing: Bool { get }
}

private extension NSView {
	
	var suitableFirstResponder: NSView? {
		for view in self.subviews {
			if let field = view as? NSTextField {
				if field.isEditable {
					return view
				}
			}
			
			if let result = view.suitableFirstResponder {
				return result
			}
		}
		
		return nil
	}
	
}

/// If you are using XUApplication, you can use XUApp as an alternative to NSApp
/// shortcut.
public let XUApp: XUApplication! = NSApp as? XUApplication

open class XUApplication: NSApplication {
	
	fileprivate var _isModal: Bool = false
	fileprivate weak var _arrowKeyEventObserver: XUArrowKeyEventsObserver? = nil
		
	
	/// Returns the current key events observer
	open var currentArrowKeyEventsObserver: XUArrowKeyEventsObserver? {
		return _arrowKeyEventObserver
	}
	
	/// Returns whether the current application is in foreground.
	open var isForegroundApplication: Bool {
		return NSRunningApplication.current().isActive
	}
	
	/// Returns true when running in modal mode
	open var isRunningInModalMode: Bool {
		return _isModal
	}
	
	/// Registers a new key events observer.
	open func registerArrowKeyEventsObserver(_ observer: XUArrowKeyEventsObserver) {
		XULog("registering \(observer) as arrow key event observer")
		_arrowKeyEventObserver = observer
	}
	
	/// Unregisters current key events observer.
	open func unregisterArrowKeyEventsObserver() {
		XULog("unregistering \(_arrowKeyEventObserver.descriptionWithDefaultValue()) as arrow key event observer")
		_arrowKeyEventObserver = nil
	}
	
	open override func runModal(for theWindow: NSWindow) -> Int {
		self.activate(ignoringOtherApps: true)
		
		_isModal = true
		
		var firstResp: NSResponder? = theWindow.firstResponder
		if firstResp == theWindow {
			firstResp = theWindow.contentView?.suitableFirstResponder
		}
		
		theWindow.makeFirstResponder(firstResp)
		
		return super.runModal(for: theWindow)
	}
	
	open override func sendEvent(_ theEvent: NSEvent) {
		if _isModal && theEvent.type == .keyDown {
			guard let w = self.keyWindow else {
				super.sendEvent(theEvent)
				return
			}
			
			let keyCode = theEvent.keyCode
			if keyCode == XUKeyCode.escape.rawValue || keyCode == XUKeyCode.enter.rawValue || keyCode == XUKeyCode.return.rawValue {
				w.makeFirstResponder(w.nextResponder)
				w.keyDown(with: theEvent)
			}else if keyCode == 9 && theEvent.modifierFlags.contains(.command) {
				// Command-V
				if let textView = w.firstResponder as? NSTextView {
					if NSPasteboard.general().string(forType: NSPasteboardTypeString) != nil {
						textView.paste(nil)
					}
				}else{
					super.sendEvent(theEvent)
				}
			}else{
				super.sendEvent(theEvent)
			}
			
			return
		}
		
		// Not modal
		var windowIsEditingAField = self.mainWindow?.firstResponder.isKind(of: NSTextView.self) ?? false
		if _arrowKeyEventObserver != nil && _arrowKeyEventObserver!.observeEvenWhenEditing {
			windowIsEditingAField = false
		}
		
		if theEvent.type == .keyDown && !windowIsEditingAField {
			let flags = theEvent.modifierFlags
			if !flags.contains(.command) && !flags.contains(.shift) && !flags.contains(.option) {
				let keyCode = theEvent.keyCode
				if keyCode == XUKeyCode.keyDown.rawValue && _arrowKeyEventObserver != nil {
					_arrowKeyEventObserver!.keyDownWasPressed(theEvent)
					return
				}else if keyCode == XUKeyCode.keyUp.rawValue && _arrowKeyEventObserver != nil {
					_arrowKeyEventObserver!.keyUpWasPressed(theEvent)
					return
				}else if (keyCode == XUKeyCode.return.rawValue || keyCode == XUKeyCode.enter.rawValue) && _arrowKeyEventObserver != nil {
					_arrowKeyEventObserver!.confirmationKeyWasPressed(theEvent)
					return
				}
			}
		}
		
		if theEvent.type == .keyUp && !windowIsEditingAField {
			let keyCode = theEvent.keyCode
			if (keyCode == XUKeyCode.escape.rawValue) && _arrowKeyEventObserver != nil {
				_arrowKeyEventObserver!.cancelationKeyWasPressed(theEvent)
				return
			}
		}

		super.sendEvent(theEvent)
	}
	
	open override func stopModal() {
		_isModal = false
		super.stopModal()
	}
	
	open override func stopModal(withCode returnCode: Int) {
		_isModal = false
		
		super.stopModal(withCode: returnCode)
	}
	
}
