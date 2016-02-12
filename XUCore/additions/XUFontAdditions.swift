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
	
	/// Returns the same font with bold trait.
	public var boldFont: XUFont? {
		#if os(iOS)
			let descriptor = self.fontDescriptor().fontDescriptorWithSymbolicTraits(.TraitBold)
			return XUFont(descriptor: descriptor, size: self.pointSize)
		#else
			let manager = NSFontManager.sharedFontManager()
			return manager.convertFont(self, toHaveTrait: .BoldFontMask)
		#endif
	}
	
	/// Returns the same font with italic trait.
	public var italicFont: XUFont? {
		#if os(iOS)
			let descriptor = self.fontDescriptor().fontDescriptorWithSymbolicTraits(.TraitItalic)
			return XUFont(descriptor: descriptor, size: self.pointSize)
		#else
			let manager = NSFontManager.sharedFontManager()
			return manager.convertFont(self, toHaveTrait: .ItalicFontMask)
		#endif
	}
	
	
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

