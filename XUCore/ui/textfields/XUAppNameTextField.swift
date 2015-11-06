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
public class XUAppNameTextField: NSTextField {

	public override func awakeFromNib() {
		super.awakeFromNib()
		
		self.localizeView()
		
		let appName = NSProcessInfo().processName
		self.stringValue = self.stringValue.stringByReplacingOccurrencesOfString("%AppName%", withString: appName)
	}
    
}


@objc(FCAppNameTextField) public class FCAppNameTextField: XUAppNameTextField {
	
	public override func awakeFromNib() {
		FCLog("WARNING: Deprecated use of \(self.dynamicType) - use XUCore.\(self.superclass!) instead")
		
		super.awakeFromNib()
	}
	
}

