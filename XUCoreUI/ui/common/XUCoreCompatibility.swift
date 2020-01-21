//
//  XUCoreCompatibility.swift
//  XUCoreUI
//
//  Created by Charlie Monroe on 1/21/20.
//  Copyright © 2020 Charlie Monroe Software. All rights reserved.
//

import Foundation
import XUCore

#if os(iOS)
	import UIKit
#else
	import Cocoa
#endif


/// This file contains several subclasses that are meant for compatibility
/// after the XUCore framework split into XUCore and XUCoreUI. This creates
/// private classes with hardcoded Objective-C names so that when they are
/// loaded from XIB files, the app doesn't crash. Additionally, they log some
/// details about where they are loaded from.

private func _printInformation(for view: __XUBridgedView) {
	XULog("Initialized deprecated view \(view).")
	#if os(iOS)
	XULog("Enclosing cell: \(view.enclosingTableViewCell.descriptionWithDefaultValue())")
	#endif
	
	XULogStacktrace("")
}


@objc(_TtC6XUCore10XULineView)
private final class __LineView: XULineView {
	
	override func awakeFromNib() {
		_printInformation(for: self)
	}
	
}

@objc(_TtC6XUCore13XURoundedView)
private final class __RoundedView: XURoundedView {
	
	override func awakeFromNib() {
		_printInformation(for: self)
	}
	
}

@objc(_TtC6XUCore21XUBorderlessTextField)
private final class __BorderlessTextField: XUBorderlessTextField {
	
	override func awakeFromNib() {
		_printInformation(for: self)
	}
	
}

@objc(_TtC6XUCore18XURoundedTextField)
private final class __RoundedTextField: XURoundedTextField {
	
	override func awakeFromNib() {
		_printInformation(for: self)
	}
	
}
