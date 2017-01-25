//
//  XUSubclassCollector.swift
//  XUCore
//
//  Created by Charlie Monroe on 11/10/15.
//  Copyright © 2015 Charlie Monroe Software. All rights reserved.
//

import Foundation
import ObjectiveC

/// This function returns true if inspectedClass is subclass of wantedSuperclass.
/// This is achieved by climbing the class tree hierarchy using class_getSuperclass
/// runtime function. This is useful when examining classes that do not have
/// NSObject as root (e.g. NSProxy subclasses).
private func XUClass(_ inspectedClass: AnyClass?, isKindOf wantedSuperclass: AnyClass?) -> Bool {
	// We've hit the root, so no, it's not
	if inspectedClass == nil {
		return false
	}

	// It's the class, yay!
	if inspectedClass == wantedSuperclass {
		return true
	}

	// Recursively call the function on the superclass of inspectedClass
	return XUClass(class_getSuperclass(inspectedClass), isKindOf: wantedSuperclass)
}

/// Works pretty much as +isKindOfClass: on NSObject, but will work fine even with
/// NSProxy subclasses, which do not respond to +isKindOfClass:
public func XUClassIsSubclassOfClass(_ superclass: AnyClass, subclass: AnyClass) -> Bool {
	return XUClass(subclass, isKindOf: superclass)
}

/// Returns a list of subclasses of class T. Doesn't include the root T class.
public func XUAllSubclasses<T: AnyObject>(of aClass: T.Type) -> [T.Type] {
	var result: [T.Type] = []

	var numClasses: Int32 = 0

	// Get the number of classes in the ObjC runtime
	numClasses = objc_getClassList(nil, 0)

	if numClasses > 0 {
		// Get them all
		let memory = malloc(MemoryLayout<AnyClass>.size * Int(numClasses))!
		defer {
			free(memory)
		}
		
		let classesPtr = memory.assumingMemoryBound(to: Optional<AnyClass>.self)
		let classes = AutoreleasingUnsafeMutablePointer<AnyClass?>(classesPtr)
		numClasses = objc_getClassList(classes, numClasses)

		for i in 0 ..< Int(numClasses) {
			// Go through the classes, find out if the class is kind of aClass
			// and then add it to the list

			guard let cl = classes[i] else {
				continue
			}

			if XUClass(cl, isKindOf: aClass) && cl != aClass {
				result.append(cl as! T.Type)
			}
		}
	}

	return result
}

