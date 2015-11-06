//
//  XUTrimmingTransformer.swift
//  XUCore
//
//  Created by Charlie Monroe on 11/6/15.
//  Copyright © 2015 Charlie Monroe Software. All rights reserved.
//

import Cocoa


/// Trims the string to the first line
public class XUStringTrimmingTransformer: NSValueTransformer {

	public override func transformedValue(value: AnyObject?) -> AnyObject? {
		if value == nil {
			//Or return nil? This partially solves the crash in removing selected snippet (in Kousek)...
			return ""
		}
		
		guard let str = value as? String else {
			NSException(name: NSInternalInconsistencyException, reason: "**** XUStringTrimmingTransformer: value not string \(value!.dynamicType)", userInfo: nil).raise()
			return nil
		}
		
		return str.lines.first!.stringByTrimmingWhitespace
	}
	
}

@objc(FCTrimmingTransformer) public class FCTrimmingTransformer: XUStringTrimmingTransformer {
	
	
	public override func transformedValue(value: AnyObject?) -> AnyObject? {
		FCLog("WARNING: Deprecated use of \(self.dynamicType) - use XUCore.\(self.superclass!) instead")
		
		return super.transformedValue(value)
	}
	
}
