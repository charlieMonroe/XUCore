//
//  XULog+iOS.swift
//  XUCoreUI iOS
//
//  Created by Charlie Monroe on 3/20/19.
//  Copyright © 2019 Charlie Monroe Software. All rights reserved.
//

import Foundation
import UIKit
import XUCore

extension XUDebugLog {
	
	/// Displays a share dialog allowing you to share the log from a controller.
	public class func shareLog(from controller: UIViewController) {
		self.flushLog()
		
		let activityController = UIActivityViewController(activityItems: [self.logFileURL], applicationActivities: nil)
		controller.present(activityController, animated: true, completion: nil)
	}
	
}
