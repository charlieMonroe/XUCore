//
//  OperatingSystemVersionExtensions.swift
//  XUCore
//
//  Created by Charlie Monroe on 10/16/17.
//  Copyright © 2017 Charlie Monroe Software. All rights reserved.
//

import Foundation

public extension OperatingSystemVersion {
	
	/// Converts this version to a version string, such as "10.13.1".
	var versionString: String {
		return "\(self.majorVersion).\(self.minorVersion).\(self.patchVersion)"
	}
	
}
