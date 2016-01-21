//
//  XUPreferencesFunctions.swift
//  DownieCore
//
//  Created by Charlie Monroe on 10/26/15.
//  Copyright © 2015 Charlie Monroe Software. All rights reserved.
//

import Foundation

public func XUPreferencesBoolForKey(key: String, defaultValue: Bool = false) -> Bool {
	guard let value = NSUserDefaults.standardUserDefaults().objectForKey(key) as? NSNumber else {
		return defaultValue
	}
	return value.boolValue
}
public func XUPreferencesSetBoolForKey(value: Bool, key: String) {
	NSUserDefaults.standardUserDefaults().setBool(value, forKey: key)
}


public func XUPreferencesIntegerForKey(key: String, defaultValue: Int = 0) -> Int {
	guard let value = NSUserDefaults.standardUserDefaults().objectForKey(key) as? NSNumber else {
		return defaultValue
	}
	return value.integerValue
}
public func XUPreferencesSetIntegerForKey(value: Int, key: String) {
	NSUserDefaults.standardUserDefaults().setInteger(value, forKey: key)
}


public func XUPreferencesObjectForKey<T>(key: String) -> T? {
	return NSUserDefaults.standardUserDefaults().objectForKey(key) as? T
}
public func XUPreferencesObjectForKey<T>(key: String, defaultValue: T) -> T {
	guard let obj = NSUserDefaults.standardUserDefaults().objectForKey(key) as? T else  {
		return defaultValue
	}
	return obj
}
public func XUPreferencesSetObjectForKey(value: AnyObject?, key: String) {
	if (value == nil){
		NSUserDefaults.standardUserDefaults().removeObjectForKey(key)
	}else{
		NSUserDefaults.standardUserDefaults().setObject(value, forKey: key)
	}
}






@available(*, deprecated, message="Use XUPreferencesBoolForKey and specify the defaultValue argument.")
public func XUPreferencesBoolForKeyWithDefaultValue(key: String, defaultValue: Bool) -> Bool {
	guard let value = NSUserDefaults.standardUserDefaults().objectForKey(key) as? NSNumber else {
		return defaultValue
	}
	return value.boolValue
}

@available(*, deprecated, message="Use XUPreferencesIntegerForKey and specify the defaultValue argument.")
public func XUPreferencesIntegerForKeyWithDefaultValue(key: String, defaultValue: Int) -> Int {
	guard let value = NSUserDefaults.standardUserDefaults().objectForKey(key) as? NSNumber else {
		return defaultValue
	}
	return value.integerValue
}

@available(*, deprecated, message="Use XUPreferencesObjectForKey and specify the defaultValue argument.")
public func XUPreferencesObjectForKeyWithDefaultValue(key: String, defaultValue: AnyObject?) -> AnyObject? {
	return XUPreferencesObjectForKey(key, defaultValue: defaultValue)
}

