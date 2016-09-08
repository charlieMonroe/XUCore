//
//  XUApplicationState.swift
//  XUCore
//
//  Created by Charlie Monroe on 8/15/16.
//  Copyright © 2016 Charlie Monroe Software. All rights reserved.
//

import Foundation

/// The exception handler can have an application state provider which should
/// include a single method. See its docs. You can set the current application
/// state provider on XUApplicationSetup.
public protocol XUApplicationStateProvider {
	
	/// Return a string that describes the application's state. E.g. if there
	/// is any network activity going on, if any documents are open, etc.
	func provideApplicationState() -> String
	
}

/// Item depicting a particular part of the application state.
/// @see XUBasicApplicationStateProvider.stateItems
public struct XUApplicationStateItem {
	
	/// Name of the item. E.g. "Running since".
	let name: String
	
	/// If true, when the application state items are transformed into a string,
	/// there is an extra new line after this block.
	let requiresAdditionalTrailingNewLine: Bool
	
	/// Value of the item. E.g. "May 14".
	let value: String
	
	/// Designated initializer.
	public init(name: String, andValue value: String, requiresAdditionalTrailingNewLine: Bool = false) {
		self.name = name
		self.value = value
		self.requiresAdditionalTrailingNewLine = requiresAdditionalTrailingNewLine
	}
	
}


/// Basic application state provider. Maintains some information about the application
/// and provides an easy way to supply additional information in a key-value
/// manner.
open class XUBasicApplicationStateProvider: XUApplicationStateProvider {
	
	/// Automatically initialized to NSDate(), providing how long has the app been
	/// running.
	open let launchTime: Date = Date()
	
	/// Returns state values. By default, this contains run-time, window list
	/// including names and perhaps in the future additional values. Override
	/// this var and append your values to what super returns.
	open var stateItems: [XUApplicationStateItem] {
		var stateItems: [XUApplicationStateItem] = [
			XUApplicationStateItem(name: "Locale", andValue: Locale.current.identifier),
			XUApplicationStateItem(name: "Beta", andValue: "\(XUAppSetup.isBetaBuild)"),
			XUApplicationStateItem(name: "AppStore", andValue: "\(XUAppSetup.isAppStoreBuild)"),
			XUApplicationStateItem(name: "Run Time", andValue: XUTime.timeString(Date.timeIntervalSinceReferenceDate - self.launchTime.timeIntervalSinceReferenceDate)),
		]
		
		#if os(OSX)
			let windows = NSApp.windows.map({ "\t\($0) - \($0.title)" }).joined(separator: "\n")
			stateItems.append(XUApplicationStateItem(name: "Window List", andValue: "\n\(windows)", requiresAdditionalTrailingNewLine: true))
		#endif
		
		return stateItems
	}
	
	public init() {}
	
	open func provideApplicationState() -> String {
		return self.stateItems.map({
			var itemString = "\($0.name): \($0.value)"
			if $0.requiresAdditionalTrailingNewLine {
				itemString += "\n"
			}
			return itemString
		}).joined(separator: "\n")
	}
	
}
