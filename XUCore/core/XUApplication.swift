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
	func cancelationKeyWasPressed(event: NSEvent)
	
	/// Either enter or return was pressed
	func confirmationKeyWasPressed(event: NSEvent)
	
	/// Key down was pressed
	func keyDownWasPressed(event: NSEvent)
	
	/// Key up was pressed
	func keyUpWasPressed(event: NSEvent)
	
	/// If true, the observer is notified even when the key responder is a text
	/// field or text view.
	var observeEvenWhenEditing: Bool { get }
}


@available(*, deprecated)
@objc public protocol FCArrowKeyEventObserver: XUArrowKeyEventsObserver {
	
}

private extension NSView {
	
	var suitableFirstResponder: NSView? {
		for view in self.subviews {
			if let field = view as? NSTextField {
				if field.editable {
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

public class XUApplication: NSApplication {
	
	private var _isModal: Bool = false
	private weak var _arrowKeyEventObserver: XUArrowKeyEventsObserver? = nil
		
	
	/// Returns the current key events observer
	public var currentArrowKeyEventsObserver: XUArrowKeyEventsObserver? {
		return _arrowKeyEventObserver
	}
	
	/// Returns whether the current application is in foreground.
	public var isForegroundApplication: Bool {
		return NSRunningApplication.currentApplication().active
	}
	
	/// Returns true when running in modal mode
	public var isRunningInModalMode: Bool {
		return _isModal
	}
	
	/// Registers a new key events observer.
	public func registerArrowKeyEventsObserver(observer: XUArrowKeyEventsObserver) {
		XULog("registering \(observer) as arrow key event observer")
		_arrowKeyEventObserver = observer
	}
	
	/// Unregisters current key events observer.
	public func unregisterArrowKeyEventsObserver() {
		XULog("unregistering \(_arrowKeyEventObserver as AnyObject? ?? "nil") as arrow key event observer")
		_arrowKeyEventObserver = nil
	}
	
	public override func runModalForWindow(theWindow: NSWindow) -> Int {
		self.activateIgnoringOtherApps(true)
		
		_isModal = true
		
		var firstResp: NSResponder? = theWindow.firstResponder
		if firstResp == theWindow {
			firstResp = theWindow.contentView?.suitableFirstResponder
		}
		
		theWindow.makeFirstResponder(firstResp)
		
		return super.runModalForWindow(theWindow)
	}
	
	public override func sendEvent(theEvent: NSEvent) {
		if _isModal && theEvent.type == .KeyDown {
			guard let w = self.keyWindow else {
				super.sendEvent(theEvent)
				return
			}
			
			let keyCode = theEvent.keyCode
			if keyCode == XUKeyCode.Escape.rawValue || keyCode == XUKeyCode.Enter.rawValue || keyCode == XUKeyCode.Return.rawValue {
				w.makeFirstResponder(w.nextResponder)
				w.keyDown(theEvent)
			}else if keyCode == 9 && theEvent.modifierFlags.contains(.CommandKeyMask) {
				// Command-V
				if let textView = w.firstResponder as? NSTextView {
					if NSPasteboard.generalPasteboard().stringForType(NSPasteboardTypeString) != nil {
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
		var windowIsEditingAField = self.mainWindow?.firstResponder.isKindOfClass(NSTextView.self) ?? false
		if _arrowKeyEventObserver != nil && _arrowKeyEventObserver!.observeEvenWhenEditing {
			windowIsEditingAField = false
		}
		
		if theEvent.type == .KeyDown && !windowIsEditingAField {
			let flags = theEvent.modifierFlags
			if !flags.contains(.CommandKeyMask) && !flags.contains(.ShiftKeyMask) && !flags.contains(.AlternateKeyMask) {
				let keyCode = theEvent.keyCode
				if keyCode == XUKeyCode.KeyDown.rawValue && _arrowKeyEventObserver != nil {
					_arrowKeyEventObserver!.keyDownWasPressed(theEvent)
					return
				}else if keyCode == XUKeyCode.KeyUp.rawValue && _arrowKeyEventObserver != nil {
					_arrowKeyEventObserver!.keyUpWasPressed(theEvent)
					return
				}else if (keyCode == XUKeyCode.Return.rawValue || keyCode == XUKeyCode.Enter.rawValue) && _arrowKeyEventObserver != nil {
					_arrowKeyEventObserver!.confirmationKeyWasPressed(theEvent)
					return
				}
			}
		}
		
		if theEvent.type == .KeyUp && !windowIsEditingAField {
			let keyCode = theEvent.keyCode
			if (keyCode == XUKeyCode.Escape.rawValue) && _arrowKeyEventObserver != nil {
				_arrowKeyEventObserver!.cancelationKeyWasPressed(theEvent)
				return
			}
		}

		super.sendEvent(theEvent)
	}
	
	public override func stopModal() {
		_isModal = false
		super.stopModal()
	}
	
	public override func stopModalWithCode(returnCode: Int) {
		_isModal = false
		
		super.stopModalWithCode(returnCode)
	}
	
}

@objc(FCApplication) class FCApplication: XUApplication {
	
	private var _warnedDeprecation: Bool = false
	
	override func sendEvent(theEvent: NSEvent) {
		if !_warnedDeprecation {
			XULog("WARNING: Use XUCore.XUApplication!")
		}
		
		super.sendEvent(theEvent)
	}
	
}
