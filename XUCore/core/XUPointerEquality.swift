//
//  XUPointerEquality.swift
//  XUCore
//
//  Created by Charlie Monroe on 1/28/17.
//  Copyright © 2017 Charlie Monroe Software. All rights reserved.
//

import Foundation

/// Implementing this protocol gets you equatability and hashability for free -
/// the pointer is used. It pretty much works like the default -isEqual: implementation
/// on NSObject.
public protocol XUPointerEquatable: AnyObject, Hashable {
	
}

public extension XUPointerEquatable {
	
	static func ==(lhs: Self, rhs: Self) -> Bool {
		return lhs === rhs
	}
	
	var hashValue: Int {
		return ObjectIdentifier(self).hashValue
	}
	
}
