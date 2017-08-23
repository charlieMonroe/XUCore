//
//  XUPreferences.swift
//  XUCore
//
//  Created by Charlie Monroe on 9/29/16.
//  Copyright © 2016 Charlie Monroe Software. All rights reserved.
//

import Foundation

/// If your extension of XUPreferences implements XUReflectablePreferences,
/// the preferences will be dumped into the debug log on init() and application
/// state provider will include them as well.
public protocol XUReflectablePreferences {
	
	var dictionaryRepresentation: XUJSONDictionary { get }
	
}

/// Extension to XUReflectablePreferences that serializes dictionaryRepresentation
/// into a loggable string.
public extension XUReflectablePreferences {
	
	/// Logs preferences using XULog.
	public func log() {
		XULog(self.logString)
	}
	
	/// Creates a string containing the reflectable properties (see XUReflectablePreferences).
	/// Will return nil, if you haven't implemented the reflectable protocol.
	public var logString: String {
		let dictItems = self.dictionaryRepresentation.sorted(by: { $0.0 < $1.0 })
		
		var result: [String] = []
		result.append("===================== XUPreferences =====================")
		
		for (key, value) in dictItems {
			result.append("| \(key) - \(value)")
		}
		
		result.append("=========================================================")
		return result.joined(separator: "\n")
	}
	
	/// State item.
	public var preferencesStateItem: XUApplicationStateItem {
		return XUApplicationStateItem(name: "Preferences", andValue: "\n" + self.logString.lines.map({ "\t" + $0 }).joined(separator: "\n"), requiresAdditionalTrailingNewLine: true)
	}
	
}


/// Preferences class. It is final, should not be subclassed, the only thing that
/// you should do is create an extension that contains computed variables for getting
/// and setting values. These vars should use the API of XUPreferences for storing
/// items.
public final class XUPreferences {
	
	/// This is a struct that identifies a key for the preferences.
	/// TODO - make it generic - this would allow some great stuff with it, but
	/// current versions of Swift do not support static stored properties on
	/// generic types, which would make all the extensions of Key with static
	/// let's incompatible.
	public struct Key: RawRepresentable, Hashable {
		
		public var hashValue: Int {
			return self.rawValue.hashValue
		}
		
		/// Raw value of the key.
		public var rawValue: String
		
		/// Initializer.
		public init(rawValue: String) {
			self.rawValue = rawValue
		}
		
	}
	
	private static var _shared: XUPreferences?
	
	/// Returns true iff the shared preferences have been inited.
	public class var isApplicationUsingPreferences: Bool {
		return _shared != nil
	}
	
	/// Returns the shared preferences.
	public class var shared: XUPreferences {
		if _shared == nil {
			_shared = XUPreferences()
			
			// Calling the reflectable preferences here instead of in the init()
			// method avoids infinite recursion if the reflectable preferences
			// need to use XUPreferences.shared.
			if let reflectable = _shared as? XUReflectablePreferences {
				reflectable.log()
			}
		}
		
		return _shared!
	}
	
	
	/// Key modifier. For example, if you need to store per-document preferences,
	/// you may init them with a `keyModifier` that adds document UUID to the key.
	/// XUPreferences' accessors (boolean(for:), etc.) then invoke this modifier
	/// to get the modified key.
	public let keyModifier: (String) -> String
	
	/// Inits self and if is reflectable, dumps contents into the log. See the
	/// `keyModifier`
	public init(keyModifier: @escaping (String) -> String = { $0 }) {
		self.keyModifier = keyModifier
	}
	
	/// Executes the block and calls synchronize on UserDefaults. This is the
	/// preferred way of modifying multiple prefereences at once - call this method
	/// with a block that sets various values and ensures that the synchronization
	/// is performed.
	public func perform(andSynchronize block: (XUPreferences) -> ()) {
		block(self)
		
		UserDefaults.standard.synchronize()
	}
	
}

/// Default accessors.
public extension XUPreferences {
	
	/// Fetches boolean for key.
	public func boolean(for key: Key, defaultValue: Bool = false) -> Bool {
		guard let value = UserDefaults.standard.object(forKey: self.keyModifier(key.rawValue)) as? NSNumber else {
			return defaultValue
		}
		return value.boolValue
	}
	
	/// Sets boolean for key.
	public func set(boolean value: Bool, forKey key: Key) {
		UserDefaults.standard.set(value, forKey: self.keyModifier(key.rawValue))
	}
	
	/// Fetches integer for key.
	public func integer(for key: Key, defaultValue: Int = 0) -> Int {
		guard let value = UserDefaults.standard.object(forKey: self.keyModifier(key.rawValue)) as? NSNumber else {
			return defaultValue
		}
		return value.intValue
	}
	
	/// Sets integer for key.
	public func set(integer value: Int, forKey key: Key) {
		UserDefaults.standard.set(value, forKey: self.keyModifier(key.rawValue))
	}
	
	/// Fetches a value for key.
	public func value<T>(for key: Key) -> T? {
		return UserDefaults.standard.object(forKey: self.keyModifier(key.rawValue)) as? T
	}
	
	/// Fetches a value with default value for key.
	public func value<T>(for key: Key, defaultValue: T) -> T {
		guard let obj = UserDefaults.standard.object(forKey: self.keyModifier(key.rawValue)) as? T else  {
			return defaultValue
		}
		return obj
	}
	
	/// Sets a value for key. Note that the value is passed to UserDefaults,
	/// so the value needs to be ObjC compatible.
	public func set(value: Any?, forKey key: Key) {
		if value == nil {
			UserDefaults.standard.removeObject(forKey: self.keyModifier(key.rawValue))
		} else {
			UserDefaults.standard.set(value, forKey: self.keyModifier(key.rawValue))
		}
	}
	
}
