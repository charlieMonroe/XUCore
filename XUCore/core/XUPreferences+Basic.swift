//
//  XUPreferences+Basic.swift
//  XUCore
//
//  Created by Charlie Monroe on 5/22/19.
//  Copyright © 2019 Charlie Monroe Software. All rights reserved.
//

import Foundation

private extension XUPreferences.Key {
	static let firstInstallationDate = XUPreferences.Key(rawValue: "XUFirstInstallationDate")
	static let launchCount = XUPreferences.Key(rawValue: "XULaunchCount")
}

extension XUPreferences {
	
	/// Launch count. You don't need to increment it manually as this gets automatically
	/// upped when the XUCoreUI framework gets initialized. When accessing this
	/// property on the first launch, the count will be 1.
	public internal(set) var launchCount: Int {
		get {
			return self.integer(for: .launchCount)
		}
		nonmutating set {
			self.set(integer: newValue, forKey: .launchCount)
		}
	}
	
	/// Returns first installation date.
	public internal(set) var firstInstallationDate: Date? {
		get {
			return self.value(for: .firstInstallationDate)
		}
		nonmutating set {
			self.set(value: newValue, forKey: .firstInstallationDate)
		}
	}
	
}
