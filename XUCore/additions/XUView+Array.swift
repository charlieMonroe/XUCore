//
//  XUView+Array.swift
//  XUCore
//
//  Created by Charlie Monroe on 7/31/18.
//  Copyright © 2018 Charlie Monroe Software. All rights reserved.
//

#if os(iOS)
	import UIKit
#else
	import Cocoa
#endif

/// These extensions allow easily setting values on collections of views.
public extension Array where Element: __XUBridgedView {
	
	/// get: Returns true if all the elements are hidden.
	/// set: Sets isHidden to newValue for all elements.
	public var isHidden: Bool {
		get {
			return self.allSatisfy({ $0.isHidden })
		}
		nonmutating set {
			self.forEach({ $0.isHidden = newValue })
		}
	}
	
}


public extension Array where Element == Optional<__XUBridgedView> {

	/// See Array<__XUBridgedView>.isHidden.
	public var isHidden: Bool {
		get {
			return self.compacted().isHidden
		}
		nonmutating set {
			self.compacted().isHidden = newValue
		}
	}
	
}
