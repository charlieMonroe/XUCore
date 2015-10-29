//
//  XUPreferencesFunctions.swift
//  DownieCore
//
//  Created by Charlie Monroe on 10/26/15.
//  Copyright © 2015 Charlie Monroe Software. All rights reserved.
//

import Cocoa

public func XUPreferencesBoolForKey(key: String) -> Bool {
	return NSUserDefaults.standardUserDefaults().boolForKey(key)
}
public func XUPreferencesBoolForKeyWithDefaultValue(key: String, defaultValue: Bool) -> Bool {
	guard let value = NSUserDefaults.standardUserDefaults().objectForKey(key) as? NSNumber else {
		return defaultValue
	}
	return value.boolValue
}
public func XUPreferencesSetBoolForKey(value: Bool, key: String) {
	NSUserDefaults.standardUserDefaults().setBool(value, forKey: key)
}


public func XUPreferencesIntegerForKey(key: String) -> Int {
	return NSUserDefaults.standardUserDefaults().integerForKey(key)
}
public func XUPreferencesIntegerForKeyWithDefaultValue(key: String, defaultValue: Int) -> Int {
	guard let value = NSUserDefaults.standardUserDefaults().objectForKey(key) as? NSNumber else {
		return defaultValue
	}
	return value.integerValue
}
public func XUPreferencesSetIntegerForKey(value: Int, key: String) {
	NSUserDefaults.standardUserDefaults().setInteger(value, forKey: key)
}


public func XUPreferencesObjectForKeyWithDefaultValue(key: String, defaultValue: AnyObject?) -> AnyObject? {
	guard let obj = NSUserDefaults.standardUserDefaults().objectForKey(key) else  {
		return defaultValue
	}
	return obj
}
public func XUPreferencesObjectForKey(key: String) -> AnyObject? {
	return XUPreferencesObjectForKeyWithDefaultValue(key, defaultValue: nil)
}
public func XUPreferencesSetObjectForKey(value: AnyObject?, key: String) {
	if (value == nil){
		NSUserDefaults.standardUserDefaults().removeObjectForKey(key)
	}else{
		NSUserDefaults.standardUserDefaults().setObject(value, forKey: key)
	}
}

