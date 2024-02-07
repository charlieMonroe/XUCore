//
//  XUStoryboardInstantiable.swift
//  XUCoreMobile
//
//  Created by Charlie Monroe on 7/13/18.
//  Copyright © 2018 Charlie Monroe Software. All rights reserved.
//

import UIKit

/// Protocol for instantiating a controller from storyboard. Given the `Self`
/// return this only works currently with final classes.
public protocol XUStoryboardInstantiable {
	
	static func instantiateFromStoryboard() -> Self
	
}

/// Special case of controllers within the main storyboard. As the storyboard
/// is specified, all you need to supply is the identifier.
public protocol XUMainStoryboardInstantiable: XUStoryboardInstantiable {
	
	/// Storyboard identifier.
	static var storyboardIdentifier: String { get }
	
}

extension XUMainStoryboardInstantiable {
	
	public static func instantiateFromStoryboard() -> Self {
		return self.instantiate(from: .main, identifier: self.storyboardIdentifier)
	}
	
}

extension UIStoryboard {
	
	/// Main storyboard in the main bundle. Do not use this if you've renamed
	/// the main storyboard or there is none in your project.
	public static let main: UIStoryboard = UIStoryboard(name: "Main", bundle: Bundle.main)
	
}

extension XUStoryboardInstantiable {
	
	/// Convenience method that casts the controller into Self.
	public static func instantiate(from storyboard: UIStoryboard, identifier: String) -> Self {
		return storyboard.instantiateViewController(withIdentifier: identifier) as! Self
	}
	
}
