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
			self.title = FCLocalizedString(self.title)
		}
	}
	
}

public extension NSTextField {
	
	public override func localizeView() {
		self.stringValue = FCLocalizedString(self.stringValue)
	}
	
}
public extension NSTabView {
	
	public override func localizeView() {
		for item in self.tabViewItems {
			item.label = FCLocalizedString(item.label)
			item.view?.localizeView()
		}
	}
	
}
public extension NSTableView {
	
	public override func localizeView() {
		for column in self.tableColumns {
			column.headerCell.title = FCLocalizedString(column.headerCell.title)
		}
	}

}
public extension NSSegmentedControl {
	
	public override func localizeView() {
		for var i = 0; i < self.segmentCount; ++i {
			if let label = self.labelForSegment(i) {
				self.setLabel(FCLocalizedString(label), forSegment: i)
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

