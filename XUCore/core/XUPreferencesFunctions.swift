//
//  XUPreferencesFunctions.swift
//  DownieCore
//
//  Created by Charlie Monroe on 10/26/15.
//  Copyright © 2015 Charlie Monroe Software. All rights reserved.
//

import Foundation

public func XUPreferencesBoolForKey(_ key: String, defaultValue: Bool = false) -> Bool {
	guard let value = UserDefaults.standard.object(forKey: key) as? NSNumber else {
		return defaultValue
	}
	return value.boolValue
}
public func XUPreferencesSetBoolForKey(_ value: Bool, key: String) {
	UserDefaults.standard.set(value, forKey: key)
}


public func XUPreferencesIntegerForKey(_ key: String, defaultValue: Int = 0) -> Int {
	guard let value = UserDefaults.standard.object(forKey: key) as? NSNumber else {
		return defaultValue
	}
	return value.intValue
}
public func XUPreferencesSetIntegerForKey(_ value: Int, key: String) {
	UserDefaults.standard.set(value, forKey: key)
}

public func XUPreferencesValueForKey<T>(_ key: String) -> T? {
	return UserDefaults.standard.object(forKey: key) as? T
}

public func XUPreferencesValueForKey<T>(_ key: String, defaultValue: T) -> T {
	guard let obj = UserDefaults.standard.object(forKey: key) as? T else  {
		return defaultValue
	}
	return obj
}

public func XUPreferencesSetValueForKey(_ value: Any?, key: String) {
	if (value == nil){
		UserDefaults.standard.removeObject(forKey: key)
	}else{
		UserDefaults.standard.set(value, forKey: key)
	}
}



@available(*, deprecated, renamed: "XUPreferencesValueForKey")
public func XUPreferencesObjectForKey<T>(_ key: String) -> T? {
	return XUPreferencesValueForKey(key)
}

@available(*, deprecated, renamed: "XUPreferencesValueForKey")
public func XUPreferencesObjectForKey<T>(_ key: String, defaultValue: T) -> T {
	return XUPreferencesValueForKey(key, defaultValue: defaultValue)
}

@available(*, deprecated, renamed: "XUPreferencesSetValueForKey")
public func XUPreferencesSetObjectForKey(_ value: Any?, key: String) {
	return XUPreferencesSetValueForKey(value, key: key)
}

@available(*, deprecated, message: "Use XUPreferencesBoolForKey and specify the defaultValue argument.")
public func XUPreferencesBoolForKeyWithDefaultValue(_ key: String, defaultValue: Bool) -> Bool {
	guard let value = UserDefaults.standard.object(forKey: key) as? NSNumber else {
		return defaultValue
	}
	return value.boolValue
}

@available(*, deprecated, message: "Use XUPreferencesIntegerForKey and specify the defaultValue argument.")
public func XUPreferencesIntegerForKeyWithDefaultValue(_ key: String, defaultValue: Int) -> Int {
	guard let value = UserDefaults.standard.object(forKey: key) as? NSNumber else {
		return defaultValue
	}
	return value.intValue
}

@available(*, deprecated, message: "Use XUPreferencesObjectForKey and specify the defaultValue argument.")
public func XUPreferencesObjectForKeyWithDefaultValue(_ key: String, defaultValue: AnyObject?) -> AnyObject? {
	return XUPreferencesObjectForKey(key, defaultValue: defaultValue)
}

