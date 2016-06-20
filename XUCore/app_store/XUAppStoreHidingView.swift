//
//  XUAppStoreHidingView.swift
//  XUCore
//
//  Created by Charlie Monroe on 11/21/15.
//  Copyright © 2015 Charlie Monroe Software. All rights reserved.
//

import AppKit

/// Hides itself if the current app configuration is an AppStore build.
public class XUAppStoreHidingView: NSView {
	
	public override func awakeFromNib() {
		super.awakeFromNib()
		
		if XUAppSetup.isAppStoreBuild {
			self.hidden = true
		}
	}
	
}

@objc(FCAppStoreHidingView) public class FCAppStoreHidingView: XUAppStoreHidingView {
	
	public override func awakeFromNib() {
		super.awakeFromNib()
		
		XULog("WARNING: Deprecated use of \(self.dynamicType) - use XUCore.\(self.superclass!) instead")
	}
	
}

