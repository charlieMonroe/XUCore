//
//  NSViewLocalizationSupport.swift
//  XUCore
//
//  Created by Charlie Monroe on 11/7/15.
//  Copyright © 2015 Charlie Monroe Software. All rights reserved.
//

import Foundation

public extension NSButton {
	
	public override func localizeView(_ bundle: Bundle = XUMainBundle) {
		self.menu?.localizeMenu(bundle)
		
		if self.imagePosition != .imageOnly || self is NSPopUpButton {
			self.title = XULocalizedString(self.title, inBundle: bundle)
		}
	}
	
}

public extension NSTextField {
	
	public override func localizeView(_ bundle: Bundle = XUMainBundle) {
		self.stringValue = XULocalizedString(self.stringValue, inBundle: bundle)
	}
	
}
public extension NSTabView {
	
	public override func localizeView(_ bundle: Bundle = XUMainBundle) {
		for item in self.tabViewItems {
			item.label = XULocalizedString(item.label, inBundle: bundle)
			item.view?.localizeView(bundle)
		}
	}
	
}
public extension NSTableView {
	
	public override func localizeView(_ bundle: Bundle = XUMainBundle) {
		for column in self.tableColumns {
			column.headerCell.title = XULocalizedString(column.headerCell.title, inBundle: bundle)
		}
	}

}
public extension NSSegmentedControl {
	
	public override func localizeView(_ bundle: Bundle = XUMainBundle) {
		for i in 0 ..< self.segmentCount {
			if let label = self.label(forSegment: i) {
				self.setLabel(XULocalizedString(label, inBundle: bundle), forSegment: i)
			}
		}
	}
	
}
public extension NSView {
	
	public func localizeView(_ bundle: Bundle = XUMainBundle) {
		for view in self.subviews {
			view.localizeView(bundle)
		}
	}
	
}

