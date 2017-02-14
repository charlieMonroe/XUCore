//
//  UITextFieldAdditions.swift
//  XUCore
//
//  Created by Charlie Monroe on 2/14/17.
//  Copyright © 2017 Charlie Monroe Software. All rights reserved.
//

import UIKit

public extension UITextField {
	
	/// Returns true if the text is nil or empty.
	var isEmpty: Bool {
		return self.text == nil || self.text!.isEmpty
	}
	
}
