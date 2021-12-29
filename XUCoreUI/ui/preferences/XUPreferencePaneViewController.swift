//
//  XUPreferencePaneViewController.swift
//  XUCore
//
//  Created by Charlie Monroe on 9/5/16.
//  Copyright © 2016 Charlie Monroe Software. All rights reserved.
//

import Cocoa
import XUCore

/// This is a base class for a view controller that is used in 
/// XUPreferencePanesWindowController. Subclass it, add your controls to it
/// and override the following:
///
/// - paneName
/// - paneIcon
/// - paneSmallIcon (optional)
/// - loadPreferences
/// - savePreferences
open class XUPreferencePaneViewController: NSViewController {

	/// Cached searchable phrases.
	private var _cachedPhrases: [String]?
	
	private func _createHeuristicalSearchablePhrases() -> [String] {
		let view = self.view
		
		var phrases: Set<String> = [self.paneName]
		let crawler = XUViewCrawler(view: view)
		for view in crawler where !view.isHidden {
			if let button = view as? NSButton, !button.title.isEmpty {
				if button is NSPopUpButton {
					continue
				}
				
				phrases.insert(button.title.replacingOccurrences(of: "\n", with: " "))
			}
			if let label = view as? NSTextField, !label.isEditable {
				let value = label.stringValue
				if value.isEmpty || value.containsCharacter(from: .punctuationCharacters) || value.containsCharacter(from: .newlines) {
					// It's a sentence.
					continue
				}
				
				phrases.insert(value)
			}
		}
		
		return Array(phrases)
	}
	
	
	/// Icon of the pane. Should be 32x32px. This must be overridden by subclasses
	/// since the default implementation ends in fatalError.
	open var paneIcon: NSImage {
		XUFatalError()
	}
	
	/// Returns a unique identifier for the view controller. This is used to
	/// identify a particular preference pane within the preferences. Default
	/// implementation uses the controller's class name as identifier, but subclasses
	/// may change this behavior.
	open var paneIdentifier: String {
		return "\(self)"
	}
	
	/// Small icon of the pane. Should be 16x16px. This is used in the menu of
	/// all panes in the window.
	///
	/// This doesn't necessarily need to be implemented, the default implementation
	/// resizes self.paneIcon to 16x16.
	open var paneSmallIcon: NSImage {
		return self.paneIcon.imageWithSingleImageRepresentation(ofSize: CGSize(width: 16.0, height: 16.0))!
	}
	
	/// Localized name of the pane. This must be overridden by subclasses since
	/// the default implementation ends in fatalError.
	open var paneName: String {
		XUFatalError()
	}

	
	/// Load the preferences and populate UI.
	open func loadPreferences() {
		// no-op
	}
	
	internal func _resetPreferences() {
		self.resetPreferences()
		self.loadPreferences()
	}
	
	/// If you return true for supportsReset, implement this method to reset
	/// settings handled by this preference pane. There is usually no need to update
	/// the UI as loadPreferences() is then called.
	///
	/// Default implementation calls XUFatalError as it needs to be overridden.
	open func resetPreferences() {
		XUFatalError()
	}
	
	/// Save the preferences from the UI.
	open func savePreferences() {
		
	}
	
	/// Returns a list of searchable phrases. This is used for search within the
	/// main window. By default, this loads the UI, crawls it a lists phrases
	/// that are heuristically likely to be options (checkboxes, labels that do
	/// not contain a sentence, etc.).
	open func searchablePhrases() -> [String] {
		if let phrases = _cachedPhrases {
			return phrases
		}
		
		let phrases = self._createHeuristicalSearchablePhrases()
		_cachedPhrases = phrases
		return phrases
	}
	
	/// If you support resetting settings in this pane, return true. The window will include a reset
	/// button in the toolbar and if the user confirms the reset, the resetPreferences() function will be called.
	open var supportsReset: Bool {
		return false
	}
	
	/// You can optionally validate any editing here. The window controller will
	/// take this into account when closing the window.
	open func validateEditing() -> Bool {
		return true
	}
	
	/// Automatically calls localizeView() on self.view. It is final and a preferred
	/// way to update anything is in loadPreferences()
	public final override func viewDidLoad() {
		super.viewDidLoad()
		
		self.view.localize(from: Bundle(for: type(of: self)))
		self.view.frame.size.width = XUPreferencePanesView.viewWidth
		self.loadPreferences()
	}
	
}
