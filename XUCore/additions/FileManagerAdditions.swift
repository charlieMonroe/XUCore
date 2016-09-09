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
	
	@available(*, deprecated, renamed: "contentsOfDirectory(at:)")
	public func contentsOfDirectoryAtURL(_ url: URL) -> [URL] {
		return self.contentsOfDirectory(at: url)
	}
	
	public func contentsOfDirectory(at url: URL) -> [URL] {
		return (try? self.contentsOfDirectory(at: url, includingPropertiesForKeys: nil, options: FileManager.DirectoryEnumerationOptions())) ?? []
	}
	
	@available(*, deprecated, renamed: "createDirectory(at:withIntermediateDirectories:)")
	@discardableResult
	public func createDirectoryAtURL(_ url: URL, withIntermediateDirectories intermediate: Bool = true) -> Bool {
		return self.createDirectory(at: url, withIntermediateDirectories: intermediate)
	}
	
	@discardableResult
	public func createDirectory(at url: URL, withIntermediateDirectories intermediate: Bool = true) -> Bool {
		do {
			try self.createDirectory(at: url, withIntermediateDirectories: intermediate, attributes: nil)
			return true
		} catch _ {
			return false
		}
	}
	
}
