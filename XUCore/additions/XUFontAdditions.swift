//
//  XUFontAdditions.swift
//  XUCore
//
//  Created by Charlie Monroe on 12/12/15.
//  Copyright © 2015 Charlie Monroe Software. All rights reserved.
//

import Foundation

#if os(iOS)
	import UIKit
	
	public typealias XUFont = UIFont
#else
	import Cocoa
	
	public typealias XUFont = NSFont
#endif

public extension XUFont {
	
	/// Creates a Helvetica font. Automatically unwrapping the optional. Since
	/// all sane systems have Helvetica installed, this is bound to work.
	public convenience init(helveticaFontOfSize size: CGFloat) {
		self.init(name: "Helvetica", size: size)!
	}
	
	/// Creates a Helvetica Bold font. Automatically unwrapping the optional.
	/// Since all sane systems have Helvetica installed, this is bound to work.
	public convenience init(boldHelveticaFontOfSize size: CGFloat) {
		self.init(name: "Helvetica Bold", size: size)!
	}
	
}

