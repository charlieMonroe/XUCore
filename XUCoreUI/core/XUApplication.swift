//
//  XUApplication.swift
//  XUCore
//
//  Created by Charlie Monroe on 11/9/15.
//  Copyright © 2015 Charlie Monroe Software. All rights reserved.
//

import Foundation
import XUCore

public protocol XUArrowKeyEventsObserver: AnyObject {
	
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


public extension NSApplication {
	
	/// Returns whether the current application is in foreground.
	var isForegroundApplication: Bool {
		return NSRunningApplication.current.isActive
	}
	
}


/// If you are using XUApplication, you can use XUApp as an alternative to NSApp
/// shortcut.
public let XUApp: XUApplication! = NSApp as? XUApplication

/// XUApplication is a sublcass of NSApplication that adds some functionality. 
/// In particular, you can add XUArrowKeyEventsObserver that can observe keyDown
/// events that are not observable inside NSTextField subclasses.
open class XUApplication: NSApplication {
	
	private var _isModal: Bool = false
	private weak var _arrowKeyEventObserver: XUArrowKeyEventsObserver? = nil
		
	
	/// Returns the current key events observer.
	public var currentArrowKeyEventsObserver: XUArrowKeyEventsObserver? {
		return _arrowKeyEventObserver
	}
	
	/// Returns true when running in modal mode
	public var isRunningInModalMode: Bool {
		return _isModal
	}
	
	/// Registers a new key events observer.
	public func registerArrowKeyEventsObserver(_ observer: XUArrowKeyEventsObserver) {
		XULog("Registering a new arrow key events observer.")
		if let observer = _arrowKeyEventObserver {
			XULog("\t\tOld observer: \(type(of: observer)) <\(Unmanaged<AnyObject>.passUnretained(observer).toOpaque())>.")
		} else {
			XULog("\t\tOld observer: None.")
		}
		
		XULog("\t\tNew observer: \(type(of: observer)) <\(Unmanaged<AnyObject>.passUnretained(observer).toOpaque())>.")
		_arrowKeyEventObserver = observer
	}
	
	/// Unregisters current key events observer.
	public func unregisterArrowKeyEventsObserver() {
		if let observer = _arrowKeyEventObserver {
			XULog("Unregistering instance of \(type(of: observer)) <\(Unmanaged<AnyObject>.passUnretained(observer).toOpaque())> as arrow key event observer.")
		} else {
			XULogStacktrace("Unregistering arrow key events observer when there is none.")
		}
		
		_arrowKeyEventObserver = nil
	}
	
	open override func runModal(for theWindow: NSWindow) -> NSApplication.ModalResponse {
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
			} else if keyCode == 9 && theEvent.modifierFlags.contains(.command) {
				// Command-V
				if let textView = w.firstResponder as? NSTextView {
					if NSPasteboard.general.string(forType: NSPasteboard.PasteboardType.string) != nil {
						textView.paste(nil)
					}
				} else {
					super.sendEvent(theEvent)
				}
			} else {
				super.sendEvent(theEvent)
			}
			
			return
		}
		
		// Not modal
		var windowIsEditingAField: Bool
		if let textView = self.mainWindow?.firstResponder as? NSTextView {
			windowIsEditingAField = true
			
			// Here is a nasty hack - as the Japanese input methods require usage
			// of key arrows and return key, we can't handle those without breaking
			// the input method. Unfortunately, I haven't found a better way to detect
			// this other than this:
			if let source = textView.inputContext?.selectedKeyboardInputSource, source.hasPrefix("com.apple.inputmethod.") {
				super.sendEvent(theEvent)
				return
			}
		} else {
			windowIsEditingAField = false
		}
		
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
				} else if keyCode == XUKeyCode.keyUp.rawValue && _arrowKeyEventObserver != nil {
					_arrowKeyEventObserver!.keyUpWasPressed(theEvent)
					return
				} else if (keyCode == XUKeyCode.return.rawValue || keyCode == XUKeyCode.enter.rawValue) && _arrowKeyEventObserver != nil {
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
	
	open override func stopModal(withCode returnCode: NSApplication.ModalResponse) {
		_isModal = false
		
		super.stopModal(withCode: returnCode)
	}
	
}
