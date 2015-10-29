//
//  FCLocalizationSupport.swift
//  DownieCore
//
//  Created by Charlie Monroe on 10/15/15.
//  Copyright © 2015 Charlie Monroe Software. All rights reserved.
//

import Foundation

public func FCLocalizedFormattedString(key: String, _ args: CVarArgType...) -> String {
	return String(format: FCLocalizedString(key), arguments: args)
}
