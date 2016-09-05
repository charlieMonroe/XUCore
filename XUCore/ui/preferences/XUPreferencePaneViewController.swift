//
//  XUPreferencePaneViewController.swift
//  XUCore
//
//  Created by Charlie Monroe on 9/5/16.
//  Copyright © 2016 Charlie Monroe Software. All rights reserved.
//

import Cocoa

/// This is a base class for a view controller that is used in 
/// XUPreferencePanesWindowController. Subclass it, add your controls to it
/// and override the following:
///
/// - paneName
/// - paneIcon
/// - paneSmallIcon (optional)
/// - loadPreferences
/// - savePreferences
public class XUPreferencePaneViewController: NSViewController {

	/// Icon of the pane. Should be 32x32px. This must be overridden by subclasses
	/// since the default implementation ends in fatalError.
	public var paneIcon: NSImage {
		XUThrowAbstractException()
	}
	
	/// Small icon of the pane. Should be 16x16px. This is used in the menu of
	/// all panes in the window.
	///
	/// This doesn't necessarily need to be implemented, the default implementation
	/// resizes self.paneIcon to 16x16.
	public var paneSmallIcon: NSImage {
		return self.paneIcon.imageWithSingleImageRepOfSize(CGSize(width: 16.0, height: 16.0))!
	}
	
	/// Localized name of the pane. This must be overridden by subclasses since
	/// the default implementation ends in fatalError.
	public var paneName: String {
		XUThrowAbstractException()
	}

	
	/// Load the preferences and populate UI.
	public func loadPreferences() {
		// no-op
	}
	
	/// Save the preferences from the UI.
	public func savePreferences() {
		
	}
	
	/// Automatically calls localizeView() on self.view.
	public override func viewDidLoad() {
		super.viewDidLoad()
		
		self.view.localizeView()
		self.view.frame.size.width = XUPreferencePanesView.viewWidth
		self.loadPreferences()
	}
	
}
