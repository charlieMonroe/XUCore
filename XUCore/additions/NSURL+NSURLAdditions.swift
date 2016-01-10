//
//  NSURL+NSURLAdditions.swift
//  XUCore
//
//  Created by Charlie Monroe on 11/10/15.
//  Copyright © 2015 Charlie Monroe Software. All rights reserved.
//

import Foundation

public extension NSURL {
	
	public class func fileReferenceURLWithPath(path: String) -> NSURL? {
		let fileURL = NSURL(fileURLWithPath: path)
		let referenceURL = fileURL.fileReferenceURL()
		return referenceURL == nil ? fileURL : referenceURL
	}
	
	public var fileSizeString: String {
		if !self.fileURL {
			return "Not Applicable (\(self))"
		}
		
		return NSByteCountFormatter.stringFromByteCount(Int64(self.fileSize), countStyle: .File)
	}
	
}


