//
//  XUFileSizeTransformer.swift
//  XUCore
//
//  Created by Charlie Monroe on 11/6/15.
//  Copyright © 2015 Charlie Monroe Software. All rights reserved.
//

import Cocoa

/// Defaults key that allows you to switch between 1024 and 1000 base.
public let XUUseBinarySizesDefaultsKey = "XUFileSizeTransformerUseBinarySizes"

private var _cachedBaseSize: Bool = false
private var kBaseSize: Double = 0.0


/// Somewhat similar to NSByteCountTransformer, but return "-- kB" in case of 0.
/// Shouldn't be used in new code, however.
public class XUFileSizeTransformer: NSValueTransformer {

	public override func transformedValue(value: AnyObject?) -> AnyObject? {
		if !_cachedBaseSize {
			if NSUserDefaults.standardUserDefaults().boolForKey(XUUseBinarySizesDefaultsKey) {
				kBaseSize = 1024.0
			}else{
				kBaseSize = 1000.0
			}
		}
		
		guard let num = value as? NSNumber else {
			return "-- kB"
		}
		
		let size = num.doubleValue
		if size <= 0 {
			return "-- kB"
		}else if size < kBaseSize {
			return String(format: "%0.00f B", size)
		}else if size < (kBaseSize * kBaseSize) {
			return String(format: "%0.00f kB", size / kBaseSize)
		}else if size < (kBaseSize * kBaseSize * kBaseSize) {
			return String(format: "%0.2f MB", size / (kBaseSize * kBaseSize))
		}else{
			return String(format: "%0.2f GB", size / (kBaseSize * kBaseSize * kBaseSize))
		}
	}
	
}


@objc public class FCFileSizeTransformer: XUFileSizeTransformer {
	
	public override func transformedValue(value: AnyObject?) -> AnyObject? {
		FCLog("WARNING: Deprecated use of \(self.dynamicType) - use XUCore.\(self.superclass!) instead")
		
		return super.transformedValue(value)
	}
	
}
