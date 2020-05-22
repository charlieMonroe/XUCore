//
//  XUSubclassCollector.swift
//  XUCore
//
//  Created by Charlie Monroe on 11/10/15.
//  Copyright © 2015 Charlie Monroe Software. All rights reserved.
//

import Foundation
import ObjectiveC

/// A struct that encloses some subclass listing methods.
public struct XUSubclassCollector {
	
	/// This function returns true if inspectedClass is subclass of wantedSuperclass.
	/// This is achieved by climbing the class tree hierarchy using class_getSuperclass
	/// runtime function. This is useful when examining classes that do not have
	/// NSObject as root (e.g. NSProxy subclasses).
	private static func _class(_ inspectedClass: AnyClass?, isKindOf wantedSuperclass: AnyClass?) -> Bool {
		// We've hit the root, so no, it's not
		if inspectedClass == nil {
			return false
		}
		
		// It's the class, yay!
		if inspectedClass == wantedSuperclass {
			return true
		}
		
		// Recursively call the function on the superclass of inspectedClass
		return self._class(class_getSuperclass(inspectedClass), isKindOf: wantedSuperclass)
	}
	
	/// Returns a list of classes that match `filter`.
	public static func allClasses(matching filter: (AnyClass) -> Bool) -> [AnyClass] {
		var numClasses: Int32 = 0
		
		// Get the number of classes in the ObjC runtime
		numClasses = objc_getClassList(nil, 0)
		
		guard numClasses > 0 else {
			return []
		}
		
		// Get them all
		let memory = malloc(MemoryLayout<AnyClass>.size * Int(numClasses))!
		defer {
			free(memory)
		}
		
		let classesPtr = memory.assumingMemoryBound(to: Optional<AnyClass>.self)
		let classes = AutoreleasingUnsafeMutablePointer<AnyClass>(classesPtr)
		numClasses = objc_getClassList(classes, numClasses)
		
		let result: [AnyClass] = (0 ..< Int(numClasses)).compactMap {
			// Go through the classes, find out if the class is kind of aClass
			// and then add it to the list
			guard let cl: AnyClass = classesPtr[$0], filter(cl) else {
				return nil
			}
			
			return cl
		}
		
		return result
	}
	
	/// Returns a list of subclasses of class T. Doesn't include the root T class.
	public static func allSubclasses<T: AnyObject>(of aClass: T.Type) -> [T.Type] {
		return self.allClasses(matching: { self._class($0, isKindOf: aClass) && $0 != aClass }) as! [T.Type]
	}
	
	/// Works pretty much as +isKindOfClass: on NSObject, but will work fine even with
	/// NSProxy subclasses, which do not respond to +isKindOfClass:
	public static func isClass(_ superclass: AnyClass, subclassOf subclass: AnyClass) -> Bool {
		return self._class(superclass, isKindOf: subclass)
	}
	
	
	/// No init.
	private init() {}
	
}

