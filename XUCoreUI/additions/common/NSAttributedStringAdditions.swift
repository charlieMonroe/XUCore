//
//  NSAttributedStringAdditions.swift
//  XUCore
//
//  Created by Charlie Monroe on 11/9/15.
//  Copyright © 2015 Charlie Monroe Software. All rights reserved.
//

#if os(macOS)
	import AppKit
#else
	import UIKit
#endif
import Foundation

public extension NSAttributedString {
	
	/// Returns all text attachments within self
	var allAttachments: [NSTextAttachment] {
		var attachments: [NSTextAttachment] = [ ]
		
		let stringRange = NSMakeRange(0, self.length)
		if stringRange.length > 0 {
			var N = 0
			repeat {
				var theEffectiveRange: NSRange = NSMakeRange(0, 0)
				let theAttributes = self.attributes(at: N, longestEffectiveRange: &theEffectiveRange, in: stringRange)
				if let attachment = theAttributes[NSAttributedString.Key.attachment] as? NSTextAttachment {
					attachments.append(attachment)
				}
				
				N = theEffectiveRange.location + theEffectiveRange.length
			} while N < stringRange.length
		}
		
		return attachments
	}
	
}


