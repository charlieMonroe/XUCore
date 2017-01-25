//
//  XUAppNameTextField.swift
//  XUCore
//
//  Created by Charlie Monroe on 11/5/15.
//  Copyright © 2015 Charlie Monroe Software. All rights reserved.
//

import Cocoa

/// Text field that replaces %AppName% with the app's name. Used in XIB files
/// that are used in multiple apps.
public final class XUAppNameTextField: NSTextField {

	public override func awakeFromNib() {
		super.awakeFromNib()
		
		self.localizeView()
		
		let appName = ProcessInfo().processName
		self.stringValue = self.stringValue.replacingOccurrences(of: "%AppName%", with: appName)
	}
    
}
