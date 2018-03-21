//
//  NSViewLocalizationSupport.swift
//  XUCore
//
//  Created by Charlie Monroe on 11/7/15.
//  Copyright © 2015 Charlie Monroe Software. All rights reserved.
//

import Foundation

public extension NSButton {
	
	public override func localize(from bundle: Bundle = Bundle.main) {
		self.menu?.localize(from: bundle)
		
		if self.imagePosition != .imageOnly || self is NSPopUpButton {
			self.title = XULocalizedString(self.title, inBundle: bundle)
		}
	}
	
}

public extension NSTextField {
	
	public override func localize(from bundle: Bundle = Bundle.main) {
		self.stringValue = XULocalizedString(self.stringValue, inBundle: bundle)
		
		if let placeholder = self.placeholderString {
			self.placeholderString = XULocalizedString(placeholder, inBundle: bundle)
		}
	}
	
}
public extension NSTabView {
	
	public override func localize(from bundle: Bundle = Bundle.main) {
		for item in self.tabViewItems {
			item.label = XULocalizedString(item.label, inBundle: bundle)
			item.view?.localize(from: bundle)
		}
	}
	
}
public extension NSTableView {
	
	public override func localize(from bundle: Bundle = Bundle.main) {
		for column in self.tableColumns {
			column.headerCell.title = XULocalizedString(column.headerCell.title, inBundle: bundle)
		}
	}

}
public extension NSSegmentedControl {
	
	public override func localize(from bundle: Bundle = Bundle.main) {
		for i in 0 ..< self.segmentCount {
			if let label = self.label(forSegment: i) {
				self.setLabel(XULocalizedString(label, inBundle: bundle), forSegment: i)
			}
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

