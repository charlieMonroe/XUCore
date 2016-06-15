//
//  NSFileManagerAdditions.swift
//  XUCore
//
//  Created by Charlie Monroe on 6/3/16.
//  Copyright © 2016 Charlie Monroe Software. All rights reserved.
//

import Foundation

/// Convenience methods that ignore some of the arguments of longer methods.
public extension NSFileManager {
	
	public func contentsOfDirectoryAtURL(url: NSURL) -> [NSURL] {
		return (try? self.contentsOfDirectoryAtURL(url, includingPropertiesForKeys: nil, options: NSDirectoryEnumerationOptions())) ?? []
	}
	
	public func createDirectoryAtURL(url: NSURL, withIntermediateDirectories intermediate: Bool = true) -> Bool {
		do {
			try self.createDirectoryAtURL(url, withIntermediateDirectories: intermediate, attributes: nil)
			return true
		} catch _ {
			return false
		}
	}
	
}
