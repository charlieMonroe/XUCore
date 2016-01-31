//
//  NSViewLocalizationSupport.swift
//  XUCore
//
//  Created by Charlie Monroe on 11/7/15.
//  Copyright © 2015 Charlie Monroe Software. All rights reserved.
//

import Foundation

public extension NSButton {
	
	public override func localizeView() {
		self.menu?.localizeMenu()
		
		if self.imagePosition != .ImageOnly || self is NSPopUpButton {
			self.title = XULocalizedString(self.title)
		}
	}
	
}

public extension NSTextField {
	
	public override func localizeView() {
		self.stringValue = XULocalizedString(self.stringValue)
	}
	
}
public extension NSTabView {
	
	public override func localizeView() {
		for item in self.tabViewItems {
			item.label = XULocalizedString(item.label)
			item.view?.localizeView()
		}
	}
	
}
public extension NSTableView {
	
	public override func localizeView() {
		for column in self.tableColumns {
			column.headerCell.title = XULocalizedString(column.headerCell.title)
		}
	}

}
public extension NSSegmentedControl {
	
	public override func localizeView() {
		for i in 0 ..< self.segmentCount {
			if let label = self.labelForSegment(i) {
				self.setLabel(XULocalizedString(label), forSegment: i)
			}
		}
	}
	
}
public extension NSView {
	
	public func localizeView() {
		for view in self.subviews {
			view.localizeView()
		}
	}
	
}

