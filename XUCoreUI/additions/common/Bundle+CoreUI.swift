//
//  Bundle+CoreUI.swift
//  XUCoreUI
//
//  Created by Charlie Monroe on 3/20/19.
//  Copyright © 2019 Charlie Monroe Software. All rights reserved.
//

import Foundation

private final class __XUCoreUIIdentifierClass { }

extension Bundle {
	
	/// Returns the core bundle.
	public static let coreUI: Bundle = Bundle(for: __XUCoreUIIdentifierClass.self)
	
}
