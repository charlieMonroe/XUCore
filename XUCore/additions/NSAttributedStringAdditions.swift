//
//  NSAttributedStringAdditions.swift
//  XUCore
//
//  Created by Charlie Monroe on 11/9/15.
//  Copyright © 2015 Charlie Monroe Software. All rights reserved.
//

import Foundation


public extension NSAttributedString {
	
	/// Returns all text attachments within self
	public var allAttachments: [NSTextAttachment] {
		var attachments: [NSTextAttachment] = [ ]
		
		let stringRange = NSMakeRange(0, self.length)
		if stringRange.length > 0 {
			var N = 0
			repeat {
				var theEffectiveRange: NSRange = NSMakeRange(0, 0)
				let theAttributes = self.attributes(at: N, longestEffectiveRange: &theEffectiveRange, in: stringRange)
				if let attachment = theAttributes[NSAttachmentAttributeName] as? NSTextAttachment {
					attachments.append(attachment)
				}
				
				N = theEffectiveRange.location + theEffectiveRange.length
			} while N < stringRange.length
		}
		
		return attachments
	}
	
}


