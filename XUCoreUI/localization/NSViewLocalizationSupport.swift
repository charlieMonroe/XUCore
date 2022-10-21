//
//  NSViewLocalizationSupport.swift
//  XUCore
//
//  Created by Charlie Monroe on 11/7/15.
//  Copyright © 2015 Charlie Monroe Software. All rights reserved.
//

import AppKit
import Foundation
import XUCore

public extension NSButton {
	
	override func localize(from bundle: Bundle = Bundle.main) {
		self.menu?.localize(from: bundle)
		
		if self.imagePosition != .imageOnly || self is NSPopUpButton {
			self.title = Localized(self.title, in: bundle)
		}
	}
	
}

public extension NSTextField {
	
	override func localize(from bundle: Bundle = Bundle.main) {
		self.stringValue = Localized(self.stringValue, in: bundle)
		
		if let placeholder = self.placeholderString {
			self.placeholderString = Localized(placeholder, in: bundle)
		}
	}
	
}
public extension NSTabView {
	
	override func localize(from bundle: Bundle = Bundle.main) {
		for item in self.tabViewItems {
			item.label = Localized(item.label, in: bundle)
			item.view?.localize(from: bundle)
		}
	}
	
}
public extension NSTableView {
	
	override func localize(from bundle: Bundle = Bundle.main) {
		for column in self.tableColumns {
			column.headerCell.title = Localized(column.headerCell.title, in: bundle)
		}
	}

}

public extension NSSegmentedControl {
	
	override func localize(from bundle: Bundle = Bundle.main) {
		for i in 0 ..< self.segmentCount {
			if let label = self.label(forSegment: i) {
				self.setLabel(Localized(label, in: bundle), forSegment: i)
			}
		}
	}
	
}

public extension NSPathControl {
	
	override func localize(from bundle: Bundle = Bundle.main) {
		if let placeholder = self.placeholderString {
			self.placeholderString = Localized(placeholder, in: bundle)
		}
	}
	
}

extension NSView: XULocalizableUIElement {
	
	@objc public func localize(from bundle: Bundle = Bundle.main) {
		for view in self.subviews {
			view.localize(from: bundle)
		}
	}
	
}

