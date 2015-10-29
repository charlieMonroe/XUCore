//
//  NSURLExtensions.swift
//  XUCore
//
//  Created by Charlie Monroe on 10/29/15.
//  Copyright © 2015 Charlie Monroe Software. All rights reserved.
//

import Foundation

public extension NSURL {
	
	public var queryDictionary: [String:String] {
		var dict: [String:String] = [:]
		for part in (self.query ?? "").componentsSeparatedByString("&") {
			let nameValParts = part.componentsSeparatedByString("=")
			let name = nameValParts[0].stringByRemovingPercentEncoding ?? ""
			let value: String
			if nameValParts.count < 2 {
				value = ""
			}else{
				value = nameValParts[1].stringByRemovingPercentEncoding ?? ""
			}
			
			dict[name] = value
		}
		
		return dict
	}
	
}

