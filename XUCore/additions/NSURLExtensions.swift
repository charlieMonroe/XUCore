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
	
	/// Returns URL with deleted fragment (i.e. the # part). Fallbacks to self.
	public var URLByDeletingFragment: NSURL {
		if self.fragment == nil {
			return self
		}
		
		guard let URLComponents = NSURLComponents(URL: self, resolvingAgainstBaseURL: true) else {
			return self
		}
		
		URLComponents.fragment = nil
		
		return URLComponents.URL ?? self
	}
	
}

