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
	import AppKit
	
	public typealias XUFont = NSFont
#endif

/// An enum that defines a font weight. This is similar to e.g UIFontWeightUltraLight,
/// but allows cross-platform behavior.
public enum XUFontWeight: Int {
	
	/// All weight values.
	static let allValues: [XUFontWeight] = [
		ultraLight, .thin, .light, .regular, .medium, .semibold, .bold, .heavy, .black
	]
	
	case ultraLight
	case thin
	case light
	case regular
	case medium
	case semibold
	case bold
	case heavy
	case black
	
	/// Returns the CGFloat value of the weight.
	public var value: CGFloat {
		#if os(iOS)
			switch self {
			case .ultraLight:
				return UIFont.Weight.ultraLight.rawValue
			case .thin:
				return UIFont.Weight.thin.rawValue
			case .light:
				return UIFont.Weight.light.rawValue
			case .regular:
				return UIFont.Weight.regular.rawValue
			case .medium:
				return UIFont.Weight.medium.rawValue
			case .semibold:
				return UIFont.Weight.semibold.rawValue
			case .bold:
				return UIFont.Weight.bold.rawValue
			case .heavy:
				return UIFont.Weight.heavy.rawValue
			case .black:
				return UIFont.Weight.black.rawValue
			}
		#elseif os(macOS)
			switch self {
			case .ultraLight:
				return NSFont.Weight.ultraLight.rawValue
			case .thin:
				return NSFont.Weight.thin.rawValue
			case .light:
				return NSFont.Weight.light.rawValue
			case .regular:
				return NSFont.Weight.regular.rawValue
			case .medium:
				return NSFont.Weight.medium.rawValue
			case .semibold:
				return NSFont.Weight.semibold.rawValue
			case .bold:
				return NSFont.Weight.bold.rawValue
			case .heavy:
				return NSFont.Weight.heavy.rawValue
			case .black:
				return NSFont.Weight.black.rawValue
			}
		#endif
	}
	
}

public extension XUFont {
		
	/// Returns the same font with bold trait.
	var boldFont: XUFont? {
		#if os(iOS)
			let descriptor = self.fontDescriptor.withSymbolicTraits(.traitBold)
			return XUFont(descriptor: descriptor!, size: self.pointSize)
		#else
			let manager = NSFontManager.shared
			return manager.convert(self, toHaveTrait: .boldFontMask)
		#endif
	}
	
	/// Returns a font with particular weight if such font is available.
	//// FIXME - doesn't work.
//	public func fontWithWeight(weight: XUFontWeight) -> XUFont? {
//		#if os(iOS)
//			var atts = self.fontDescriptor().fontAttributes()
//			atts[UIFontWidthTrait] = weight.value
//			return UIFont(descriptor: UIFontDescriptor(fontAttributes: atts), size: self.pointSize)
//		#else
//			var attributes = self.fontDescriptor.fontAttributes
//			attributes[NSFontWidthTrait] = weight.value
//			return NSFont(descriptor: NSFontDescriptor(fontAttributes: attributes), size: self.pointSize)
//		#endif
//	}
	
	/// Returns the same font with italic trait.
	var italicFont: XUFont? {
		#if os(iOS)
			let descriptor = self.fontDescriptor.withSymbolicTraits(.traitItalic)
			return XUFont(descriptor: descriptor!, size: self.pointSize)
		#else
			let manager = NSFontManager.shared
			return manager.convert(self, toHaveTrait: .italicFontMask)
		#endif
	}
	
	
	/// Creates a Helvetica font. Automatically unwrapping the optional. Since
	/// all sane systems have Helvetica installed, this is bound to work.
	convenience init(helveticaFontOfSize size: CGFloat) {
		self.init(name: "Helvetica", size: size)!
	}
	
	/// Creates a Helvetica Bold font. Automatically unwrapping the optional.
	/// Since all sane systems have Helvetica installed, this is bound to work.
	convenience init(boldHelveticaFontOfSize size: CGFloat) {
		self.init(name: "Helvetica Bold", size: size)!
	}
	
}

