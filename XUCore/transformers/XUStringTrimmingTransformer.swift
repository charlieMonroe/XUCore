//
//  XUTrimmingTransformer.swift
//  XUCore
//
//  Created by Charlie Monroe on 11/6/15.
//  Copyright © 2015 Charlie Monroe Software. All rights reserved.
//

import Foundation


/// Trims the string to the first line
open class XUStringTrimmingTransformer: ValueTransformer {

	open override func transformedValue(_ value: Any?) -> Any? {
		if value == nil {
			//Or return nil? This partially solves the crash in removing selected snippet (in Kousek)...
			return ""
		}
		
		guard let str = value as? String else {
			NSException(name: NSExceptionName.internalInconsistencyException, reason: "**** XUStringTrimmingTransformer: value not string \(type(of: (value!) as AnyObject))", userInfo: nil).raise()
			return nil
		}
		
		return str.lines.first!.trimmingWhitespace
	}
	
}
