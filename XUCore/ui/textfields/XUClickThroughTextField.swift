//
//  XUClickThroughTextField.swift
//  XUCore
//
//  Created by Charlie Monroe on 1/15/16.
//  Copyright © 2016 Charlie Monroe Software. All rights reserved.
//

import Foundation

/// This class is for labels used in controls, where they need to be click-through.
public final class XUClickThroughTextField: NSTextField {
	
	public override var description: String {
		return "\(super.description) hidden: \(self.isHidden)"
	}
	public override var mouseDownCanMoveWindow: Bool {
		return false
	}
	public override func hitTest(_ aPoint: CGPoint) -> NSView? {
		return nil
	}
	
}
