//
//  NSAppearanceAdditions.swift
//  XUCoreUI
//
//  Created by Charlie Monroe on 10/10/19.
//  Copyright © 2019 Charlie Monroe Software. All rights reserved.
//

import AppKit
import Foundation

extension NSAppearance {
	
	public var isDark: Bool {
		if #available(macOS 10.14, *) {
			return self.bestMatch(from: [.darkAqua, .vibrantDark]) != nil
		} else {
			return self.name == .vibrantDark
		}
	}
	
}
