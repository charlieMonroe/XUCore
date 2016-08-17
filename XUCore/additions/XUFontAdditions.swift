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

/// An enum that defines a font weight. This is similar to e.g UIFontWeightUltraLight,
/// but allows cross-platform behavior.
public enum XUFontWeight: Int {
	
	/// All weight values.
	static let allValues: [XUFontWeight] = [
		UltraLight, .Thin, .Light, .Regular, .Medium, .Semibold, .Bold, .Heavy, .Black
	]
	
	case UltraLight
	case Thin
	case Light
	case Regular
	case Medium
	case Semibold
	case Bold
	case Heavy
	case Black
	
	/// Returns the CGFloat value of the weight.
	public var value: CGFloat {
		#if os(iOS)
			switch self {
			case .UltraLight:
				return UIFontWeightUltraLight
			case .Thin:
				return UIFontWeightThin
			case .Light:
				return UIFontWeightLight
			case .Regular:
				return UIFontWeightRegular
			case .Medium:
				return UIFontWeightMedium
			case .Semibold:
				return UIFontWeightSemibold
			case .Bold:
				return UIFontWeightBold
			case .Heavy:
				return UIFontWeightHeavy
			case .Black:
				return UIFontWeightBlack
			}
		#elseif os(OSX)
			if #available(OSX 10.11, *) {
				switch self {
				case .UltraLight:
					return NSFontWeightUltraLight
				case .Thin:
					return NSFontWeightThin
				case .Light:
					return NSFontWeightLight
				case .Regular:
					return NSFontWeightRegular
				case .Medium:
					return NSFontWeightMedium
				case .Semibold:
					return NSFontWeightSemibold
				case .Bold:
					return NSFontWeightBold
				case .Heavy:
					return NSFontWeightHeavy
				case .Black:
					return NSFontWeightBlack
				}
			} else {
				switch self {
				case .UltraLight:
					return -0.800000011920929
				case .Thin:
					return -0.600000023841858
				case .Light:
					return -0.400000005960464
				case .Regular:
					return 0.0
				case .Medium:
					return 0.230000004172325
				case .Semibold:
					return 0.300000011920929
				case .Bold:
					return 0.400000005960464
				case .Heavy:
					return 0.560000002384186
				case .Black:
					return 0.620000004768372
				}
			}
		#endif
	}
	
}

public extension XUFont {
	
	/// Returns system font of size with a particular weight. Since the system font
	/// should include all weights, the returned value is IUO, instead of a pure
	/// optional.
	public class func systemFontOfSize(pointSize: CGFloat, withWeight weight: XUFontWeight) -> XUFont! {
		if #available(OSX 10.11, *) {
			return self.systemFontOfSize(pointSize, weight: weight.value)
		} else {
			if weight.rawValue <= XUFontWeight.Regular.rawValue {
				return self.systemFontOfSize(pointSize)
			} else {
				return self.boldSystemFontOfSize(pointSize)
			}
		}
	}
	
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

