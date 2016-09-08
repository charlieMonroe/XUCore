//
//  NSURL+NSURLAdditions.swift
//  XUCore
//
//  Created by Charlie Monroe on 11/10/15.
//  Copyright © 2015 Charlie Monroe Software. All rights reserved.
//

import Foundation

public extension URL {
	
	@available(*, deprecated)
	public static func fileReferenceURLWithPath(_ path: String) -> URL? {
		let fileURL = URL(fileURLWithPath: path)
		return (fileURL as NSURL).fileReferenceURL()
	}
	
	@available(*, deprecated)
	public var fileSizeString: String {
		if !self.isFileURL {
			return "Not Applicable (\(self))"
		}
		
		return ByteCountFormatter.string(fromByteCount: Int64(self.fileSize), countStyle: .file)
	}
	
}


