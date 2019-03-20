//
//  XUAppStoreHidingView.swift
//  XUCore
//
//  Created by Charlie Monroe on 11/21/15.
//  Copyright © 2015 Charlie Monroe Software. All rights reserved.
//

import AppKit
import XUCore

/// Hides itself if the current app configuration is an AppStore build.
open class XUAppStoreHidingView: NSView {
	
	open override func awakeFromNib() {
		super.awakeFromNib()
		
		if XUAppSetup.isAppStoreBuild {
			self.isHidden = true
		}
	}
	
}
