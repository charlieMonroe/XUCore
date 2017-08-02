//
//  Process+Additions.swift
//  XUCore
//
//  Created by Charlie Monroe on 8/2/17.
//  Copyright © 2017 Charlie Monroe Software. All rights reserved.
//

import Foundation

public extension Process {
	
	
	/// Waits until exits and reads all data as string (from stdout). This will
	/// set self.standardOutput to a new pipe. If you have previously set it to
	/// something else, it will be overwritten.
	///
	/// - Returns: String value of the output.
	public func launchAndReadAllData() -> String {
		let pipe = Pipe()
		let fileHandle = pipe.fileHandleForReading
		self.standardOutput = pipe
		
		self.launch()
		
		var result = ""
		
		while self.isRunning {
			let data = fileHandle.availableData
			guard let output = String(data: data) else {
				continue
			}
			
			result += output
		}
		
		self.waitUntilExit() // Just to be sure.
		
		if let output = String(data: fileHandle.availableData) {
			result += output
		}
		
		return result
	}
	
}
