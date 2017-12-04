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
	
	public struct Directories {
	
		/// Returns application support directory.
		public static var applicationSupportDirectory: URL {
			return try! FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
		}
		
	}
	
	public func contentsOfDirectory(at url: URL) -> [URL] {
		return (try? self.contentsOfDirectory(at: url, includingPropertiesForKeys: nil, options: FileManager.DirectoryEnumerationOptions())) ?? []
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
