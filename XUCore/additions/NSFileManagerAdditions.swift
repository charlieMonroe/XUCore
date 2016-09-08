//
//  NSFileManagerAdditions.swift
//  XUCore
//
//  Created by Charlie Monroe on 6/3/16.
//  Copyright © 2016 Charlie Monroe Software. All rights reserved.
//

import Foundation

/// Convenience methods that ignore some of the arguments of longer methods.
public extension FileManager {
	
	public func contentsOfDirectoryAtURL(_ url: URL) -> [URL] {
		return (try? self.contentsOfDirectory(at: url, includingPropertiesForKeys: nil, options: FileManager.DirectoryEnumerationOptions())) ?? []
	}
	
	@discardableResult
	public func createDirectoryAtURL(_ url: URL, withIntermediateDirectories intermediate: Bool = true) -> Bool {
		do {
			try self.createDirectory(at: url, withIntermediateDirectories: intermediate, attributes: nil)
			return true
		} catch _ {
			return false
		}
	}
	
}
